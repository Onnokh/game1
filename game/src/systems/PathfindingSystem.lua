local System = require("src.core.System")
local TiledMapLoader = require("src.utils.TiledMapLoader")

---@class PathfindingSystem : System
---@field worldMap table The 2D world map array
---@field worldWidth number Width of the world in tiles
---@field worldHeight number Height of the world in tiles
---@field tileSize number Size of each tile in pixels
---@field grid table|nil Jumper grid object
---@field pathfinder table|nil Jumper pathfinder object
---@field entityCollisionSize number Collision size to account for in pathfinding
---@field entityCollisionWidth number Width of entity collision box
---@field entityCollisionHeight number Height of entity collision box
---@field clearance number Clearance value for pathfinding in tiles
---@field physicsWorld table|nil The physics world for collision detection
local PathfindingSystem = System:extend("PathfindingSystem", {"Position", "Pathfinding"})

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

    -- Calculate clearance in tiles for pathfinding
    local clearanceX = math.ceil(self.entityCollisionWidth / self.tileSize)
    local clearanceY = math.ceil(self.entityCollisionHeight / self.tileSize)
    self.clearance = math.max(clearanceX, clearanceY) -- Use the larger dimension

    -- Initialize Jumper pathfinding
    self:initializePathfinding()

    return self
end


---Add an entity to this system
---@param entity Entity The entity to add
function PathfindingSystem:addEntity(entity)
    System.addEntity(self, entity)

    -- Set up pathfinder for this entity if it has pathfinding component
    local pathfinding = entity:getComponent("Pathfinding")
    if pathfinding and self.grid and self.pathfinder then
        pathfinding:setPathfinder(self.grid, self.pathfinder, self.clearance)
        pathfinding.entityId = entity.id -- Store entity ID for debug output
    end

    -- If this entity has a pathfinding collision component, rebuild the pathfinding grid
    local pathfindingCollision = entity:getComponent("PathfindingCollision")
    if pathfindingCollision and self.grid and self.pathfinder then
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
            local tileType = self.worldMap[x][y]
            collisionMap[x][y] = TiledMapLoader.isWalkable(tileType) and 1 or 0
        end
    end

    -- Add collision objects to the pathfinding grid
    self:addCollisionObjectsToGrid(collisionMap)


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

    -- Calculate clearance based on entity collision size in tiles
    local clearanceX = math.ceil(self.entityCollisionWidth / self.tileSize)
    local clearanceY = math.ceil(self.entityCollisionHeight / self.tileSize)
    local clearance = math.max(clearanceX, clearanceY) -- Use the larger dimension


    self.pathfinder = Pathfinder(self.grid, 'JPS', 1) -- JPS algorithm, walkable value is 1
    self.pathfinder:annotateGrid() -- Calculate clearance values for the grid

    -- Set up pathfinder for all entities
    for _, entity in ipairs(self.entities) do
        local pathfinding = entity:getComponent("Pathfinding")
        if pathfinding then
            pathfinding:setPathfinder(self.grid, self.pathfinder, self.clearance)
        end
    end
end

---Add collision objects to the pathfinding grid
---@param collisionMap table The collision map to modify
function PathfindingSystem:addCollisionObjectsToGrid(collisionMap)
    local collisionCount = 0

		-- Get all entities with pathfinding collision components
		for i, entity in ipairs(self.entities) do
			local pathfindingCollision = entity:getComponent("PathfindingCollision")
			local position = entity:getComponent("Position")

			-- Process both static and dynamic collision objects for pathfinding
			if pathfindingCollision and position then
				if pathfindingCollision:hasCollider() then
					collisionCount = collisionCount + 1
					-- Get collision bounds in grid coordinates
					local colliderX, colliderY = pathfindingCollision:getPosition()
					local gridX1 = math.floor(colliderX / 16) + 1
					local gridY1 = math.floor(colliderY / 16) + 1
					local gridX2 = math.floor((colliderX + pathfindingCollision.width) / 16) + 1
					local gridY2 = math.floor((colliderY + pathfindingCollision.height) / 16) + 1

					-- Mark collision area as blocked (0 = blocked)
					for x = gridX1, gridX2 do
						for y = gridY1, gridY2 do
							if x >= 1 and x <= self.worldWidth and y >= 1 and y <= self.worldHeight then
								collisionMap[x][y] = 0
							end
						end
					end
				end
			end
		end
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
            local tileType = self.worldMap[x][y]
            collisionMap[x][y] = TiledMapLoader.isWalkable(tileType) and 1 or 0
        end
    end

    -- Add collision objects to the pathfinding grid
    self:addCollisionObjectsToGrid(collisionMap)


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

    -- Calculate clearance based on entity collision size in tiles
    local clearanceX = math.ceil(self.entityCollisionWidth / self.tileSize)
    local clearanceY = math.ceil(self.entityCollisionHeight / self.tileSize)
    local clearance = math.max(clearanceX, clearanceY) -- Use the larger dimension

    self.pathfinder = Pathfinder(self.grid, 'JPS', 1) -- JPS algorithm, walkable value is 1
    self.pathfinder:annotateGrid() -- Calculate clearance values for the grid

    -- Update pathfinders for all entities
    for _, entity in ipairs(self.entities) do
        local pathfinding = entity:getComponent("Pathfinding")
        if pathfinding then
            pathfinding:setPathfinder(self.grid, self.pathfinder, self.clearance)
        end
    end
end

---Update all entities with pathfinding
---@param dt number Delta time
function PathfindingSystem:update(dt)
    -- Rebuild pathfinding grid periodically to account for moving entities
    -- This is expensive, so we do it less frequently than every frame
    local currentTime = love.timer.getTime()
    if not self.lastGridRebuild then
        self.lastGridRebuild = currentTime
    end

    -- Rebuild grid every 0.5 seconds to account for moving entities
    if currentTime - self.lastGridRebuild > 0.5 then
        self:rebuildPathfindingGrid()
        self.lastGridRebuild = currentTime
    end

    for _, entity in ipairs(self.entities) do
        local position = entity:getComponent("Position")
        local pathfinding = entity:getComponent("Pathfinding")
        local movement = entity:getComponent("Movement")
        local knockback = entity:getComponent("Knockback")

        if position and pathfinding and movement then
            -- Ensure pathfinder is set up for this entity
            if not pathfinding.pathfinder or not pathfinding.grid then
                pathfinding:setPathfinder(self.grid, self.pathfinder, self.clearance)
            end

            self:updateEntityPathfinding(entity, position, pathfinding, dt)

            -- Steering toward waypoint: compute desired velocity here
            if not pathfinding:isPathComplete() and not knockback then
                local nextX, nextY = pathfinding:getNextPathPosition()
                if nextX and nextY then
                    local pathfindingCollision = entity:getComponent("PathfindingCollision")
                    local cx, cy = position.x, position.y
                    if pathfindingCollision and pathfindingCollision:hasCollider() then
                        cx, cy = pathfindingCollision:getCenterPosition()
                    end
                    local dx, dy = nextX - cx, nextY - cy
                    local dist = math.sqrt(dx*dx + dy*dy)
                    if dist > 0 then
                        -- Default walk factor; optionally override per-entity later
                        local walkFactor = 0.6
                        movement.velocityX = (dx / dist) * (movement.maxSpeed * walkFactor)
                        movement.velocityY = (dy / dist) * (movement.maxSpeed * walkFactor)
                    end
                end
            end
        end
    end
end

---Update pathfinding for a specific entity
---@param entity Entity The entity to update
---@param position Position The position component
---@param pathfinding Pathfinding The pathfinding component
---@param dt number Delta time
function PathfindingSystem:updateEntityPathfinding(entity, position, pathfinding, dt)
    -- If we have a path, only manage progression along waypoints; do not set velocity here
    if not pathfinding:isPathComplete() then
        local nextX, nextY = pathfinding:getNextPathPosition()
        if nextX and nextY then
            local pathfindingCollision = entity:getComponent("PathfindingCollision")
            local currentX, currentY = position.x, position.y
            if pathfindingCollision and pathfindingCollision:hasCollider() then
                currentX, currentY = pathfindingCollision:getCenterPosition()
            end

            local dx = nextX - currentX
            local dy = nextY - currentY
            local distance = math.sqrt(dx * dx + dy * dy)
            if distance < self.tileSize * 0.3 then
                pathfinding:advancePath()
            end
        end
    end
end

return PathfindingSystem
