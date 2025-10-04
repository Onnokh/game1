-- Import System base class
local System = require("src.core.System")

---@class PathfindingSystem : System
---@field worldMap table The 2D world map array
---@field worldWidth number Width of the world in tiles
---@field worldHeight number Height of the world in tiles
---@field tileSize number Size of each tile in pixels
---@field grid table|nil Jumper grid object
---@field pathfinder table|nil Jumper pathfinder object
---@field entityCollisionSize number Collision size to account for in pathfinding
---@field physicsWorld table|nil The physics world for collision detection
local PathfindingSystem = setmetatable({}, {__index = System})
PathfindingSystem.__index = PathfindingSystem

---Create a new PathfindingSystem
---@param worldMap table The 2D world map array
---@param worldWidth number Width of the world in tiles
---@param worldHeight number Height of the world in tiles
---@param tileSize number Size of each tile in pixels
---@return PathfindingSystem|System
function PathfindingSystem.new(worldMap, worldWidth, worldHeight, tileSize)
    local self = System.new({"Position"}) -- Track all entities with Position component
    setmetatable(self, PathfindingSystem)

    self.worldMap = worldMap
    self.worldWidth = worldWidth
    self.worldHeight = worldHeight
    self.tileSize = tileSize

    -- Hardcoded collision size for skeleton (12x18 pixels)
    -- TODO: Make this dynamic per entity in the future
    self.entityCollisionSize = 18 -- Use the larger dimension
    self.entityCollisionWidth = 12 -- Width of collision box
    self.entityCollisionHeight = 18 -- Height of collision box

    -- Initialize Jumper pathfinding
    self:initializePathfinding()

    return self
end

---Expand collision boundaries to account for entity collision size
---@param collisionMap table The collision map to modify
function PathfindingSystem:expandCollisionBoundaries(collisionMap)
    if self.entityCollisionSize <= self.tileSize then
        return -- No expansion needed if entity fits in one tile
    end

    -- Calculate expansion radius based on entity collision size
    -- We need to account for the fact that the entity's collision box is offset from its visual center
    local expansionRadiusX = math.ceil(self.entityCollisionWidth / (2 * self.tileSize))
    local expansionRadiusY = math.ceil(self.entityCollisionHeight / (2 * self.tileSize))
    print("PathfindingSystem: Expanding collision boundaries by", expansionRadiusX, "x", expansionRadiusY, "tiles for entity size", self.entityCollisionWidth, "x", self.entityCollisionHeight)

    -- Create a copy of the original collision map
    local originalMap = {}
    for x = 1, self.worldWidth do
        originalMap[x] = {}
        for y = 1, self.worldHeight do
            originalMap[x][y] = collisionMap[x][y]
        end
    end

    -- Expand blocked areas
    for x = 1, self.worldWidth do
        for y = 1, self.worldHeight do
            if originalMap[x][y] == 0 then -- If this tile is blocked
                -- Mark surrounding tiles as blocked based on entity size
                -- Use rectangular expansion to match collision box shape
                for dx = -expansionRadiusX, expansionRadiusX do
                    for dy = -expansionRadiusY, expansionRadiusY do
                        local newX = x + dx
                        local newY = y + dy

                        -- Check if this expansion tile is within bounds
                        if newX >= 1 and newX <= self.worldWidth and newY >= 1 and newY <= self.worldHeight then
                            collisionMap[newX][newY] = 0
                        end
                    end
                end
            end
        end
    end
end

---Add an entity to this system
---@param entity Entity The entity to add
function PathfindingSystem:addEntity(entity)
    System.addEntity(self, entity)

    -- Set up pathfinder for this entity if it has pathfinding component
    local pathfinding = entity:getComponent("Pathfinding")
    if pathfinding and self.grid and self.pathfinder then
        pathfinding:setPathfinder(self.grid, self.pathfinder)
        pathfinding.entityId = entity.id -- Store entity ID for debug output
    end

    -- If this is a static collision entity, rebuild the pathfinding grid
    local collision = entity:getComponent("Collision")
    if collision and collision.type == "static" and self.grid and self.pathfinder then
        print("PathfindingSystem: Rebuilding grid due to static collision entity")
        self:rebuildPathfindingGrid()
    end
end

---Initialize the Jumper pathfinding system
function PathfindingSystem:initializePathfinding()
    local Grid = require("lib.jumper.grid")
    local Pathfinder = require("lib.jumper.pathfinder")

    -- Create a collision map for pathfinding (1 = walkable, 0 = blocked)
    local collisionMap = {}
    for x = 1, self.worldWidth do
        collisionMap[x] = {}
        for y = 1, self.worldHeight do
            -- 1 = walkable (grass), 0 = blocked (walls)
            collisionMap[x][y] = self.worldMap[x][y] == 1 and 1 or 0
        end
    end

    -- Add collision objects to the pathfinding grid
    self:addCollisionObjectsToGrid(collisionMap)

    -- Expand collision boundaries to account for entity collision size
    self:expandCollisionBoundaries(collisionMap)

    -- Transpose collision map for Jumper (expects map[y][x] format)
    local transposedMap = {}
    for y = 1, self.worldHeight do
        transposedMap[y] = {}
        for x = 1, self.worldWidth do
            transposedMap[y][x] = collisionMap[x][y]
        end
    end

    -- Create grid and pathfinder
    self.grid = Grid(transposedMap)
    self.pathfinder = Pathfinder(self.grid, 'JPS', 1) -- JPS algorithm, walkable value is 1

    -- Set up pathfinder for all entities
    for _, entity in ipairs(self.entities) do
        local pathfinding = entity:getComponent("Pathfinding")
        if pathfinding then
            pathfinding:setPathfinder(self.grid, self.pathfinder)
        end
    end
end

---Add collision objects to the pathfinding grid
---@param collisionMap table The collision map to modify
function PathfindingSystem:addCollisionObjectsToGrid(collisionMap)
    local collisionCount = 0
    print("PathfindingSystem: Processing", #self.entities, "entities for static collision")

    -- Get all entities with collision components
    for i, entity in ipairs(self.entities) do
        local collision = entity:getComponent("Collision")
        local position = entity:getComponent("Position")

        print("PathfindingSystem: Entity", i, "collision:", collision and collision.type or "none", "position:", position and "yes" or "no")

        -- Only process static collision objects (ignore moving entities)
        if collision and position and collision.type == "static" then
            print("PathfindingSystem: Found static collision entity", i)
            if collision:hasCollider() then
                collisionCount = collisionCount + 1
                -- Get collision bounds in grid coordinates
                local colliderX, colliderY = collision:getPosition()
                local gridX1 = math.floor(colliderX / 16) + 1
                local gridY1 = math.floor(colliderY / 16) + 1
                local gridX2 = math.floor((colliderX + collision.width) / 16) + 1
                local gridY2 = math.floor((colliderY + collision.height) / 16) + 1

                print("PathfindingSystem: Static collision at", colliderX, colliderY, "size", collision.width, "x", collision.height)
                print("PathfindingSystem: Grid bounds", gridX1, gridY1, "to", gridX2, gridY2)

                -- Mark collision area as blocked (0 = blocked)
                for x = gridX1, gridX2 do
                    for y = gridY1, gridY2 do
                        if x >= 1 and x <= self.worldWidth and y >= 1 and y <= self.worldHeight then
                            collisionMap[x][y] = 0
                        end
                    end
                end
            else
                print("PathfindingSystem: Static collision entity has no collider")
            end
        end
    end

    print("PathfindingSystem: Processed", collisionCount, "static collision objects")
end

---Rebuild the pathfinding grid with current collision data
function PathfindingSystem:rebuildPathfindingGrid()
    if not self.worldMap then
        return
    end

    local Grid = require("lib.jumper.grid")
    local Pathfinder = require("lib.jumper.pathfinder")

    -- Create a fresh collision map
    local collisionMap = {}
    for x = 1, self.worldWidth do
        collisionMap[x] = {}
        for y = 1, self.worldHeight do
            -- 1 = walkable (grass), 0 = blocked (walls)
            collisionMap[x][y] = self.worldMap[x][y] == 1 and 1 or 0
        end
    end

    -- Add collision objects to the pathfinding grid
    self:addCollisionObjectsToGrid(collisionMap)

    -- Expand collision boundaries to account for entity collision size
    self:expandCollisionBoundaries(collisionMap)

    -- Transpose collision map for Jumper (expects map[y][x] format)
    local transposedMap = {}
    for y = 1, self.worldHeight do
        transposedMap[y] = {}
        for x = 1, self.worldWidth do
            transposedMap[y][x] = collisionMap[x][y]
        end
    end

    -- Create new grid and pathfinder
    self.grid = Grid(transposedMap)
    self.pathfinder = Pathfinder(self.grid, 'JPS', 1)

    -- Update pathfinders for all entities
    for _, entity in ipairs(self.entities) do
        local pathfinding = entity:getComponent("Pathfinding")
        if pathfinding then
            pathfinding:setPathfinder(self.grid, self.pathfinder)
        end
    end
end

---Update all entities with pathfinding
---@param dt number Delta time
function PathfindingSystem:update(dt)
    for _, entity in ipairs(self.entities) do
        local position = entity:getComponent("Position")
        local movement = entity:getComponent("Movement")
        local pathfinding = entity:getComponent("Pathfinding")

        -- Only process entities that have pathfinding components
        if position and movement and pathfinding then
            -- Ensure pathfinder is set up for this entity
            if not pathfinding.pathfinder or not pathfinding.grid then
                pathfinding:setPathfinder(self.grid, self.pathfinder)
            end

            self:updateEntityPathfinding(entity, position, movement, pathfinding, dt)
        end
    end
end

---Update pathfinding for a specific entity
---@param entity Entity The entity to update
---@param position Position The position component
---@param movement Movement The movement component
---@param pathfinding Pathfinding The pathfinding component
---@param dt number Delta time
function PathfindingSystem:updateEntityPathfinding(entity, position, movement, pathfinding, dt)
    -- Update wander timer
    pathfinding.lastWanderTime = pathfinding.lastWanderTime + dt

    -- Check if we need to start a new wander (only when path is complete, not when there's no path)
    if pathfinding:isPathComplete() and pathfinding.lastWanderTime >= pathfinding.wanderCooldown then
        local success = pathfinding:startWander(position.x, position.y, self.tileSize)
        if not success then
            -- If we can't find a path, try again in a shorter time
            pathfinding.lastWanderTime = pathfinding.wanderCooldown - 1.0
        end
    end

    -- If we have a path, move towards the next waypoint
    if not pathfinding:isPathComplete() then
        local nextX, nextY = pathfinding:getNextPathPosition(self.tileSize)

        if nextX and nextY then
            -- Get the collision center position for accurate movement calculation
            local collision = entity:getComponent("Collision")
            local currentX, currentY = position.x, position.y

            if collision and collision:hasCollider() then
                -- Use collision center position for movement calculation
                currentX, currentY = collision:getPosition()
                currentX = currentX + collision.width / 2
                currentY = currentY + collision.height / 2
            end

            -- Calculate direction to next waypoint
            local dx = nextX - currentX
            local dy = nextY - currentY
            local distance = math.sqrt(dx * dx + dy * dy)

            -- If we're close enough to the waypoint, move to the next one
            if distance < self.tileSize * 0.3 then -- Within 30% of tile size
                pathfinding:advancePath()
                nextX, nextY = pathfinding:getNextPathPosition(self.tileSize)
                if nextX and nextY then
                    dx = nextX - currentX
                    dy = nextY - currentY
                    distance = math.sqrt(dx * dx + dy * dy)
                end
            end

            -- Set movement direction
            if distance > 0 then
                local speed = movement.maxSpeed * 0.4 -- Slower than player
                movement.velocityX = (dx / distance) * speed
                movement.velocityY = (dy / distance) * speed
                movement.direction = tostring(math.atan2(dy, dx))
            else
                -- Stop moving if we've reached the target
                movement.velocityX = 0
                movement.velocityY = 0
            end
        end
    else
        -- No path, stop moving
        movement.velocityX = 0
        movement.velocityY = 0
    end
end

return PathfindingSystem
