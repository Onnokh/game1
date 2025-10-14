local System = require("src.core.System")

---@class PathfindingSystem : System
---@field worldMap table The 2D world map array
---@field worldWidth number Width of the world in tiles
---@field worldHeight number Height of the world in tiles
---@field tileSize number Size of each tile in pixels
---@field grid table|nil Jumper grid object
---@field pathfinder table|nil Jumper pathfinder object
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

    -- Initialize Jumper pathfinding
    self:initializePathfinding()

    return self
end


---Calculate clearance for an entity based on its PathfindingCollision component
---@param entity Entity The entity to calculate clearance for
---@return number clearance The clearance value in tiles
function PathfindingSystem:calculateEntityClearance(entity)
    local pathfindingCollision = entity:getComponent("PathfindingCollision")
    if pathfindingCollision then
        -- Calculate clearance based on the entity's collision size
        local clearanceX = math.ceil(pathfindingCollision.width / self.tileSize)
        local clearanceY = math.ceil(pathfindingCollision.height / self.tileSize)
        return math.max(clearanceX, clearanceY)
    end
    -- Default clearance if no PathfindingCollision component
    return 1
end

---Add an entity to this system
---@param entity Entity The entity to add
function PathfindingSystem:addEntity(entity)
    System.addEntity(self, entity)

    -- Set up pathfinder for this entity if it has pathfinding component
    local pathfinding = entity:getComponent("Pathfinding")
    if pathfinding and self.grid and self.pathfinder then
        -- Calculate clearance based on entity's PathfindingCollision component
        local clearance = self:calculateEntityClearance(entity)
        pathfinding:setPathfinder(self.grid, self.pathfinder, clearance)
        pathfinding.entityId = entity.id -- Store entity ID for debug output
    end

    -- OPTIMIZATION: Don't rebuild grid when entities are added
    -- Only STATIC entities block pathfinding, and they're added during initial load
    -- Dynamic entities (monsters, player) don't block pathfinding for other entities
end

---Remove an entity from this system
---@param entity Entity The entity to remove
function PathfindingSystem:removeEntity(entity)
    System.removeEntity(self, entity)

    -- Only rebuild if this was a static collision entity that blocks pathfinding
    local pathfindingCollision = entity:getComponent("PathfindingCollision")
    if pathfindingCollision and pathfindingCollision.type == "static" and self.grid and self.pathfinder then
        -- Rebuild grid when static entities are removed (e.g., destroyed trees)
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
            local tileData = self.worldMap[x][y]
            -- worldMap cells are tables with {type=..., gid=..., walkable=...}
            local isWalkable = tileData and tileData.walkable or false
            collisionMap[x][y] = isWalkable and 1 or 0
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

    -- Use JPS for fast pathfinding (annotation only happens once at load)
    self.pathfinder = Pathfinder(self.grid, 'JPS', 1) -- JPS algorithm, walkable value is 1

    -- Annotate grid for JPS
    local annotateStart = love.timer.getTime()
    self.pathfinder:annotateGrid()
    print(string.format("[PathfindingSystem] Grid annotation took %.2fs", love.timer.getTime() - annotateStart))

    -- Set up pathfinder for all entities with their own clearance values
    for _, entity in ipairs(self.entities) do
        local pathfinding = entity:getComponent("Pathfinding")
        if pathfinding then
            local clearance = self:calculateEntityClearance(entity)
            pathfinding:setPathfinder(self.grid, self.pathfinder, clearance)
        end
    end
end

---Add collision objects to the pathfinding grid
---@param collisionMap table The collision map to modify
function PathfindingSystem:addCollisionObjectsToGrid(collisionMap)
		local CoordinateUtils = require("src.utils.coordinates")

		-- Get all entities with pathfinding collision components
		for i, entity in ipairs(self.entities) do
			local pathfindingCollision = entity:getComponent("PathfindingCollision")
			local position = entity:getComponent("Position")

			-- Only process STATIC collision objects for pathfinding grid
			-- Dynamic entities (monsters) should NOT block pathfinding
			if pathfindingCollision and position and pathfindingCollision.type == "static" then
				if pathfindingCollision:hasCollider() then
					-- Get collision bounds in grid coordinates using CoordinateUtils
					local colliderX, colliderY = pathfindingCollision:getPosition()
					local gridX1, gridY1 = CoordinateUtils.worldToGrid(colliderX, colliderY)
					local gridX2, gridY2 = CoordinateUtils.worldToGrid(
						colliderX + pathfindingCollision.width,
						colliderY + pathfindingCollision.height
					)

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
            local tileData = self.worldMap[x][y]
            -- worldMap cells are tables with {type=..., gid=..., walkable=...}
            local isWalkable = tileData and tileData.walkable or false
            collisionMap[x][y] = isWalkable and 1 or 0
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

    -- Use JPS for fast pathfinding
    self.pathfinder = Pathfinder(self.grid, 'JPS', 1)
    -- NOTE: Skip annotation during rebuild (too expensive for runtime)
    -- Paths will still work but without clearance optimization

    -- Update pathfinders for all entities with their own clearance values
    for _, entity in ipairs(self.entities) do
        local pathfinding = entity:getComponent("Pathfinding")
        if pathfinding then
            local clearance = self:calculateEntityClearance(entity)
            pathfinding:setPathfinder(self.grid, self.pathfinder, clearance)
        end
    end
end

---Update all entities with pathfinding
---@param dt number Delta time
function PathfindingSystem:update(dt)
    -- NOTE: Grid rebuilding is now event-driven (only when entities are added/removed)
    -- No need for periodic rebuilds since dynamic entities don't block pathfinding

    for _, entity in ipairs(self.entities) do
        local position = entity:getComponent("Position")
        local pathfinding = entity:getComponent("Pathfinding")
        local movement = entity:getComponent("Movement")
        local knockback = entity:getComponent("Knockback")

        if position and pathfinding and movement then
            -- Ensure pathfinder is set up for this entity
            if not pathfinding.pathfinder or not pathfinding.grid then
                local clearance = self:calculateEntityClearance(entity)
                pathfinding:setPathfinder(self.grid, self.pathfinder, clearance)
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
