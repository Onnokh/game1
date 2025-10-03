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
    self.minWanderDistance = 1.0 -- Minimum distance in tiles for new destinations
    self.pathfinder = nil
    self.grid = nil
    return self
end

---Set the pathfinding grid and pathfinder
---@param grid table The Jumper grid object
---@param pathfinder table The Jumper pathfinder object
function Pathfinding:setPathfinder(grid, pathfinder)
    self.grid = grid
    self.pathfinder = pathfinder
end

---Find a random wander target within the radius
---@param currentX number Current X position
---@param currentY number Current Y position
---@return number targetX
---@return number targetY
function Pathfinding:findWanderTarget(currentX, currentY)
    local attempts = 0
    local maxAttempts = 10

    while attempts < maxAttempts do
        local angle = math.random() * 2 * math.pi
        local distance = math.random() * self.wanderRadius * 16 -- Convert tiles to pixels
        local targetX = self.spawnX + math.cos(angle) * distance
        local targetY = self.spawnY + math.sin(angle) * distance

        -- Check if target is far enough from current position
        local dx = targetX - currentX
        local dy = targetY - currentY
        local distanceFromCurrent = math.sqrt(dx * dx + dy * dy)

        if distanceFromCurrent >= self.minWanderDistance * 16 then -- Convert tiles to pixels
            return targetX, targetY
        end

        attempts = attempts + 1
    end

    -- If we can't find a good target, just return a random one
    local angle = math.random() * 2 * math.pi
    local distance = math.random() * self.wanderRadius * 16 -- Convert tiles to pixels
    local targetX = self.spawnX + math.cos(angle) * distance
    local targetY = self.spawnY + math.sin(angle) * distance
    return targetX, targetY
end

---Convert world coordinates to grid coordinates
---@param worldX number World X coordinate
---@param worldY number World Y coordinate
---@param tileSize number Size of each tile
---@return number gridX
---@return number gridY
function Pathfinding:worldToGrid(worldX, worldY, tileSize)
    local gridX = math.floor(worldX / tileSize) + 1
    local gridY = math.floor(worldY / tileSize) + 1
    return gridX, gridY
end

---Convert grid coordinates to world coordinates
---@param gridX number Grid X coordinate
---@param gridY number Grid Y coordinate
---@param tileSize number Size of each tile
---@return number worldX
---@return number worldY
function Pathfinding:gridToWorld(gridX, gridY, tileSize)
    local worldX = (gridX - 1) * tileSize + tileSize / 2
    local worldY = (gridY - 1) * tileSize + tileSize / 2
    return worldX, worldY
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
---@param tileSize number Size of each tile
---@return number|nil nextX
---@return number|nil nextY
function Pathfinding:getNextPathPosition(tileSize)
    if not self.currentPath or self.pathIndex > #self.currentPath._nodes then
        return nil, nil
    end

    local node = self.currentPath._nodes[self.pathIndex]
    if not node then
        return nil, nil
    end

    local gridX, gridY = node._x, node._y
    return self:gridToWorld(gridX, gridY, tileSize)
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

---Start a new wander to a random target
---@param currentX number Current X position
---@param currentY number Current Y position
---@param tileSize number Size of each tile
---@return boolean success
function Pathfinding:startWander(currentX, currentY, tileSize)
    if not self.pathfinder or not self.grid then
        print("Pathfinding: No pathfinder or grid available")
        return false
    end

    -- Find a new wander target
    local targetX, targetY = self:findWanderTarget(currentX, currentY)

    -- Convert to grid coordinates
    local startGridX, startGridY = self:worldToGrid(currentX, currentY, tileSize)
    local targetGridX, targetGridY = self:worldToGrid(targetX, targetY, tileSize)

    -- Ensure target is within grid bounds
    local minX, minY, maxX, maxY = self.grid:getBounds()
    local gridWidth = maxX - minX + 1
    local gridHeight = maxY - minY + 1
    targetGridX = math.max(minX, math.min(targetGridX, maxX))
    targetGridY = math.max(minY, math.min(targetGridY, maxY))

    -- Find path
    local path = self.pathfinder:getPath(startGridX, startGridY, targetGridX, targetGridY)

    if path and path._nodes and #path._nodes > 0 then
        self.currentPath = path
        self.pathIndex = 1
        self.targetX = targetX
        self.targetY = targetY
        self.isWandering = true
        self.lastWanderTime = 0
        return true
    else
        print("Pathfinding: No path found from", startGridX, startGridY, "to", targetGridX, targetGridY)
        return false
    end
end

return Pathfinding
