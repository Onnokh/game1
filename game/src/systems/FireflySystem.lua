local System = require("src.core.System")
local FireflyFactory = require("src.entities.Firefly")

---@class FireflySystem : System
---@field worldBounds table World bounds {x, y, width, height}
---@field spawnTimer table Spawn timer for fireflies
local FireflySystem = System:extend("FireflySystem", {"Position", "Firefly", "Light"})

---Create a new FireflySystem
---@return FireflySystem
function FireflySystem.new()
    local self = System.new()
    setmetatable(self, FireflySystem)
    self.requiredComponents = {"Position", "Firefly", "Light"}
    self.worldBounds = { x = 0, y = 0, width = 600, height = 600 }
    self.worldGrid = nil  -- Will be set later when world is loaded
    self.tileSize = 32    -- Default tile size, will be updated from world data

    -- Single spawn timer for the world
    self.spawnTimer = {
        nextSpawn = math.random() * 3,  -- Initial random delay 0-3 seconds
        interval = 8 + math.random() * 2  -- 8-10 second intervals
    }

    return self
end

---Update firefly spawning timers and spawn new fireflies
---@param dt number Delta time
function FireflySystem:update(dt)
    -- Update spawn timer
    self.spawnTimer.nextSpawn = self.spawnTimer.nextSpawn - dt

    if self.spawnTimer.nextSpawn <= 0 then
        self:spawnFireflies()
        self.spawnTimer.nextSpawn = self.spawnTimer.interval
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

---Spawn fireflies in the world
function FireflySystem:spawnFireflies()
    -- Spawn 0-1 clusters of fireflies
    local clusterCount = math.random(1)

    for cluster = 1, clusterCount do
        -- Find a cluster center position
        local centerX, centerY = self:findWalkablePosition()

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

                -- Make sure the position is still within world bounds and walkable
                if x >= self.worldBounds.x and x <= self.worldBounds.x + self.worldBounds.width and
                   y >= self.worldBounds.y and y <= self.worldBounds.y + self.worldBounds.height and
                   self:isWalkable(x, y) then
                    local firefly = FireflyFactory.create(x, y, self.world)
                end
            end
        end
    end
end

---Set the world bounds (called when world is loaded)
---@param x number World X position
---@param y number World Y position
---@param width number World width
---@param height number World height
function FireflySystem:setWorldBounds(x, y, width, height)
    self.worldBounds = { x = x or 0, y = y or 0, width = width or 600, height = height or 600 }
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

---Find a walkable position within the world
---@return number|nil, number|nil X and Y coordinates, or nil if no walkable position found
function FireflySystem:findWalkablePosition()
    local maxAttempts = 50  -- Maximum attempts to find a walkable position

    for attempt = 1, maxAttempts do
        -- Generate random position within world bounds (avoid edges where walls are)
        local margin = self.tileSize * 2  -- Avoid edge walls
        local x = self.worldBounds.x + margin + math.random(self.worldBounds.width - margin * 2)
        local y = self.worldBounds.y + margin + math.random(self.worldBounds.height - margin * 2)

        -- Check if position is walkable
        if self:isWalkable(x, y) then
            return x, y
        end
    end

    -- If no walkable position found after max attempts, return nil
    return nil, nil
end

return FireflySystem
