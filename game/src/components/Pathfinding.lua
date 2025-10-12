local CoordinateUtils = require("src.utils.coordinates")
local GameConstants = require("src.constants")

---@class Pathfinding : Component
---Component for pathfinding and AI behavior
---@field spawnX number X coordinate of spawn location
---@field spawnY number Y coordinate of spawn location
---@field wanderRadius number Maximum distance from spawn to wander
---@field currentPath table|nil Current path object
---@field pathIndex number Current position in path
---@field targetX number|nil Target X coordinate
---@field targetY number|nil Target Y coordinate
---@field lastWanderTime number Time since last wander
---@field wanderCooldown number Cooldown between wanders
---@field isWandering boolean Whether currently wandering
---@field pathfinder table|nil Jumper pathfinder object
---@field grid table|nil Jumper grid object
---@field clearance number Clearance value for pathfinding
local Pathfinding = {}
Pathfinding.__index = Pathfinding
setmetatable(Pathfinding, {__index = require("src.core.Component")})

---Create a new Pathfinding component
---@param spawnX number X coordinate of spawn location
---@param spawnY number Y coordinate of spawn location
---@param wanderRadius number Maximum distance from spawn to wander
---@return Pathfinding
function Pathfinding.new(spawnX, spawnY, wanderRadius)
    local self = setmetatable({}, Pathfinding)
    self.spawnX = spawnX
    self.spawnY = spawnY
    self.wanderRadius = wanderRadius or 1 -- Default 5 tiles
    self.currentPath = nil
    self.pathIndex = 1
    self.targetX = nil
    self.targetY = nil
    self.lastWanderTime = 0
    self.wanderCooldown = 2.0 -- Wait 5 seconds between wandering
    self.isWandering = false
    self.pathfinder = nil
    self.grid = nil
    return self
end

---Set the pathfinding grid and pathfinder
---@param grid table The Jumper grid object
---@param pathfinder table The Jumper pathfinder object
---@param clearance number|nil The clearance value for pathfinding
function Pathfinding:setPathfinder(grid, pathfinder, clearance)
    self.grid = grid
    self.pathfinder = pathfinder
    self.clearance = clearance or 1 -- Default to 1 if not provided
end

---Find a random wander target within the radius
---@param currentX number Current X position
---@param currentY number Current Y position
---@return number|nil targetX
---@return number|nil targetY
function Pathfinding:findWanderTarget(currentX, currentY)
    local EntityUtils = require("src.utils.entities")

    -- Convert spawn position to grid coordinates
    local spawnGridX, spawnGridY = CoordinateUtils.worldToGrid(self.spawnX, self.spawnY)

    -- Find all walkable tiles in radius
    local validTiles = EntityUtils.findValidTilesInRadius(spawnGridX, spawnGridY, self.wanderRadius)

    -- If no valid tiles found, return nil
    if #validTiles == 0 then
        return nil, nil
    end

    -- Pick a random valid tile
    local randomTile = validTiles[math.random(#validTiles)]

    -- Convert back to world coordinates (center of tile)
    local targetX, targetY = CoordinateUtils.gridToWorld(randomTile.x, randomTile.y)

    return targetX, targetY
end


---Check if a position is within the wander radius
---@param x number X coordinate
---@param y number Y coordinate
---@return boolean
function Pathfinding:isWithinRadius(x, y)
    local dx = x - self.spawnX
    local dy = y - self.spawnY
    local distance = math.sqrt(dx * dx + dy * dy)
    return distance <= self.wanderRadius
end


---Get the next position in the current path
---@return number|nil nextX
---@return number|nil nextY
function Pathfinding:getNextPathPosition()
    if not self.currentPath or self.pathIndex > #self.currentPath._nodes then
        return nil, nil
    end

    local node = self.currentPath._nodes[self.pathIndex]
    if not node then
        return nil, nil
    end

    local gridX, gridY = node._x, node._y
    return CoordinateUtils.gridToWorld(gridX, gridY)
end

---Move to the next position in the path
function Pathfinding:advancePath()
    if self.currentPath and self.pathIndex <= #self.currentPath._nodes then
        self.pathIndex = self.pathIndex + 1
    end
end

---Check if the path is complete
---@return boolean
function Pathfinding:isPathComplete()
    return not self.currentPath or self.pathIndex > #self.currentPath._nodes
end

---Start a path towards a specific world target (in pixels)
---@param currentX number Current X position (world pixels)
---@param currentY number Current Y position (world pixels)
---@param targetX number Target X position (world pixels)
---@param targetY number Target Y position (world pixels)
---@return boolean success
function Pathfinding:startPathTo(currentX, currentY, targetX, targetY)
    if not self.pathfinder or not self.grid then
        return false
    end

    -- Clamp current position to world bounds before using it
    currentX, currentY = CoordinateUtils.clampToWorldBounds(currentX, currentY)

    -- Validate that both current and target positions are within world bounds
    if not CoordinateUtils.isWithinWorldBounds(currentX, currentY, self.grid) or not CoordinateUtils.isWithinWorldBounds(targetX, targetY, self.grid) then
        return false
    end

    local startGridX, startGridY = CoordinateUtils.worldToGrid(currentX, currentY)
    local targetGridX, targetGridY = CoordinateUtils.worldToGrid(targetX, targetY)

    local path = self.pathfinder:getPath(startGridX, startGridY, targetGridX, targetGridY, self.clearance)
    if path and path._nodes and #path._nodes > 0 then
        self.currentPath = path
        self.pathIndex = 1
        self.targetX = targetX
        self.targetY = targetY
        self.isWandering = false
        return true
    else
        return false
    end
end

---Start a new wander to a random target
---@param currentX number Current X position
---@param currentY number Current Y position
---@return boolean success
function Pathfinding:startWander(currentX, currentY)

    if not self.pathfinder or not self.grid then
        print("[Pathfinding] startWander failed: no pathfinder or grid")
        return false
    end

    -- Clamp current position to world bounds before using it
    currentX, currentY = CoordinateUtils.clampToWorldBounds(currentX, currentY)

    -- Find a new wander target
    local targetX, targetY = self:findWanderTarget(currentX, currentY)

    -- If no valid target found, fail early
    if not targetX or not targetY then
        print(string.format("[Pathfinding] startWander failed: no valid target from (%.0f, %.0f)", currentX, currentY))
        return false
    end

    -- Convert to grid coordinates
    local startGridX, startGridY = CoordinateUtils.worldToGrid(currentX, currentY)
    local targetGridX, targetGridY = CoordinateUtils.worldToGrid(targetX, targetY)

    -- Ensure target is within grid bounds using coordinate utilities
    targetGridX, targetGridY = CoordinateUtils.clampToGridBounds(targetGridX, targetGridY, self.grid)

    -- Debug: Check if start and target are walkable
    local startWalkable = self.grid:isWalkableAt(startGridX, startGridY, 1)
    local targetWalkable = self.grid:isWalkableAt(targetGridX, targetGridY, 1)

    if not startWalkable then
        print(string.format("[Pathfinding] START tile (%d,%d) is NOT walkable!", startGridX, startGridY))
        return false
    end

    if not targetWalkable then
        print(string.format("[Pathfinding] TARGET tile (%d,%d) is NOT walkable!", targetGridX, targetGridY))
        return false
    end

    -- Find path (skip clearance to avoid requiring annotation)
    local path = self.pathfinder:getPath(startGridX, startGridY, targetGridX, targetGridY)

    if path and path._nodes and #path._nodes > 0 then
        self.currentPath = path
        self.pathIndex = 1
        self.targetX = targetX
        self.targetY = targetY
        self.isWandering = true
        self.lastWanderTime = 0
        print(string.format("[Pathfinding] startWander SUCCESS: path from (%d,%d) to (%d,%d) with %d nodes",
            startGridX, startGridY, targetGridX, targetGridY, #path._nodes))
        return true
    else
        -- Debug: Check grid values directly
        local gridMap = self.grid:getMap()
        local startValue = gridMap[startGridY] and gridMap[startGridY][startGridX]
        local targetValue = gridMap[targetGridY] and gridMap[targetGridY][targetGridX]
        print(string.format("[Pathfinding] startWander failed: no path from (%d,%d)[value=%s] to (%d,%d)[value=%s]",
            startGridX, startGridY, tostring(startValue),
            targetGridX, targetGridY, tostring(targetValue)))
        return false
    end
end

return Pathfinding
