local System = require("src.core.System")
local FireflyFactory = require("src.entities.Firefly")

---@class FireflySystem : System
---@field islands table Array of island data for spawn locations
---@field spawnTimers table Spawn timers for each island
local FireflySystem = System:extend("FireflySystem", {"Position", "Firefly", "Light"})

---Create a new FireflySystem
---@param islands table|nil Array of island data for spawn locations
---@return FireflySystem
function FireflySystem.new(islands)
    local self = System.new()
    setmetatable(self, FireflySystem)
    self.requiredComponents = {"Position", "Firefly", "Light"}
    self.islands = islands or {}
    self.worldGrid = nil  -- Will be set later when world is loaded
    self.tileSize = 32    -- Default tile size, will be updated from world data

    -- Spawn timers for each island with fireflies property
    self.spawnTimers = {}
    for _, island in ipairs(self.islands) do
        if island.definition and island.definition.properties and island.definition.properties.fireflies then
            self.spawnTimers[island.id] = {
                nextSpawn = math.random() * 3,  -- Initial random delay 0-3 seconds
                interval = 8 + math.random() * 2  -- 8-10 second intervals
            }
        end
    end

    return self
end

---Update firefly spawning timers and spawn new fireflies
---@param dt number Delta time
function FireflySystem:update(dt)
    -- Update spawn timers for each island
    for islandId, timer in pairs(self.spawnTimers) do
        timer.nextSpawn = timer.nextSpawn - dt

        if timer.nextSpawn <= 0 then
            self:spawnFirefliesForIsland(islandId)
            timer.nextSpawn = timer.interval
        end
    end

    -- Update existing fireflies
    for _, entity in ipairs(self.entities) do
        local position = entity:getComponent("Position")
        local firefly = entity:getComponent("Firefly")
        local light = entity:getComponent("Light")
        local spriteRenderer = entity:getComponent("SpriteRenderer")

        if position and firefly and light then
            -- Update firefly lifetime
            firefly:update(dt)

            -- Calculate movement with drift
            local currentTime = love.timer.getTime()
            local driftOffset = firefly:getDriftOffset(currentTime)
            local newX = position.x + firefly.vx * dt + driftOffset * dt
            local newY = position.y + firefly.vy * dt

            -- Update position
            position.x = newX
            position.y = newY

            -- Update alpha based on fade-in and lifetime for both light and sprite
            local combinedAlpha = firefly:getCombinedAlpha()
            if light.a then
                light.a = math.floor(200 * combinedAlpha)
            end

            -- Update sprite alpha
            if spriteRenderer and spriteRenderer.color then
                spriteRenderer.color.a = 0.6 * combinedAlpha
            end

                -- Remove firefly if lifetime expired
                if not firefly:isAlive() then
                    -- Properly remove from world to clean up all components including lights
                    if self.world then
                        self.world:removeEntity(entity)
                    else
                        entity:destroy()
                    end
                end
        end
    end
end

---Spawn fireflies for a specific island
---@param islandId string Island identifier
function FireflySystem:spawnFirefliesForIsland(islandId)
    -- Find the island data
    local island = nil
    for _, islandData in ipairs(self.islands) do
        if islandData.id == islandId then
            island = islandData
            break
        end
    end

    if not island then return end

    -- Spawn 0-1 clusters of fireflies
    local clusterCount = math.random(1)

    for cluster = 1, clusterCount do
        -- Find a cluster center position
        local centerX, centerY = self:findWalkablePosition(island)

        if centerX and centerY then
            -- Spawn 2-4 fireflies in a cluster around the center
            local clusterSize = 2 + math.random(3)  -- 2-4 fireflies per cluster
            local clusterRadius = 40 + math.random(20)  -- 40-60 pixel radius

            for i = 1, clusterSize do
                -- Generate position within cluster radius
                local angle = math.random() * math.pi * 2
                local distance = math.random() * clusterRadius
                local x = centerX + math.cos(angle) * distance
                local y = centerY + math.sin(angle) * distance

                -- Make sure the position is still within island bounds and walkable
                    if x >= island.x and x <= island.x + island.width and
                       y >= island.y and y <= island.y + island.height and
                       self:isWalkable(x, y) then
                        local firefly = FireflyFactory.create(x, y, self.world)
                    end
            end
            end
    end
end

---Set the islands data (called when islands are loaded)
---@param islands table Array of island data
function FireflySystem:setIslands(islands)
    self.islands = islands

    -- Reset spawn timers for new islands
    self.spawnTimers = {}
    for _, island in ipairs(self.islands) do
        if island.definition and island.definition.properties and island.definition.properties.fireflies then
            self.spawnTimers[island.id] = {
                nextSpawn = math.random() * 3,  -- Initial random delay 0-3 seconds
                interval = 8 + math.random() * 2  -- 8-10 second intervals
            }
        end
    end
end

---Set the world grid data for walkability checking
---@param worldGrid table The pathfinding grid
---@param tileSize number Tile size in pixels
function FireflySystem:setWorldGrid(worldGrid, tileSize)
    self.worldGrid = worldGrid
    self.tileSize = tileSize or 32
end

---Check if a position is on a walkable tile
---@param x number World X position
---@param y number World Y position
---@return boolean True if the position is walkable
function FireflySystem:isWalkable(x, y)
    if not self.worldGrid or not self.tileSize then
        return true  -- Default to walkable if no grid data
    end

    local tileX = math.floor(x / self.tileSize) + 1
    local tileY = math.floor(y / self.tileSize) + 1

    if self.worldGrid[tileX] and self.worldGrid[tileX][tileY] then
        return self.worldGrid[tileX][tileY].walkable == true
    end

    return false  -- Default to not walkable if tile doesn't exist
end

---Find a walkable position within an island
---@param island table Island data
---@return number|nil, number|nil X and Y coordinates, or nil if no walkable position found
function FireflySystem:findWalkablePosition(island)
    local maxAttempts = 50  -- Maximum attempts to find a walkable position

    for attempt = 1, maxAttempts do
        -- Generate random position within island bounds
        local x = island.x + math.random(island.width)
        local y = island.y + math.random(island.height)

        -- Check if position is walkable
        if self:isWalkable(x, y) then
            return x, y
        end
    end

    -- If no walkable position found after max attempts, return nil
    return nil, nil
end

return FireflySystem
