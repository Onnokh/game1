local System = require("src.core.System")
local GameTimeManager = require("src.core.managers.GameTimeManager")

-- Lazy-loaded monster modules
local Slime = nil
local Skeleton = nil
local Warthog = nil

---@class EnemySpawnerSystem : System
---@field ecsWorld World
---@field physicsWorld love.World
---@field waves table Wave definitions
---@field currentWaveIndex number Current active wave index
---@field spawnTimer number Timer for spawn rate control
---@field lastSpawnTime number Time of last spawn
local EnemySpawnerSystem = System:extend("EnemySpawnerSystem", {})

---Initialize the enemy spawner system
---@param ecsWorld World ECS world
---@param physicsWorld love.World Physics world
---@return EnemySpawnerSystem
function EnemySpawnerSystem.new(ecsWorld, physicsWorld)
    local self = System.new()
    setmetatable(self, EnemySpawnerSystem)

    self.ecsWorld = ecsWorld
    self.physicsWorld = physicsWorld
    self.waves = require("src.definitions.enemy_waves")
    self.currentWaveIndex = 1
    self.spawnTimer = 0
    self.lastSpawnTime = 0

    -- Lazy load monster modules
    self:loadMonsterModules()

    print("[EnemySpawnerSystem] Initialized with", #self.waves, "waves")
    return self
end

---Lazy load monster modules
function EnemySpawnerSystem:loadMonsterModules()
    if not Slime then
        Slime = require("src.entities.Monsters.Slime.Slime")
    end
    if not Skeleton then
        Skeleton = require("src.entities.Monsters.Skeleton.Skeleton")
    end
    if not Warthog then
        Warthog = require("src.entities.Monsters.Warhog.Warhog")
    end
end

---Get the currently active wave based on elapsed time
---@return table|nil Active wave or nil if no wave is active
---@return number|nil Wave index or nil if no wave is active
function EnemySpawnerSystem:getActiveWave()
    local currentTime = GameTimeManager.getTime()

    -- Find the wave that should be active based on current time
    for i, wave in ipairs(self.waves) do
        if currentTime >= wave.time then
            -- Check if this wave is still active (hasn't ended)
            if currentTime < wave.time + wave.duration then
                return wave, i
            end
        end
    end

    -- If no wave is active, check if we should start the first wave
    if currentTime >= self.waves[1].time then
        return self.waves[1], 1
    end

    return nil, nil
end

---Calculate spawn position based on shape and player position
---@param shape table Shape definition
---@param playerX number Player X position
---@param playerY number Player Y position
---@return number, number Spawn X and Y coordinates
function EnemySpawnerSystem:calculateSpawnPosition(shape, playerX, playerY)
    if shape.type == "circle" then
        local maxAttempts = 10

        -- First, try to find valid positions at the exact radius
        for attempt = 1, maxAttempts do
            local angle = math.random() * 2 * math.pi
            local radius = shape.radius -- Use exact radius, not random
            local x = playerX + math.cos(angle) * radius
            local y = playerY + math.sin(angle) * radius

            local enemyCenterX = x + 16
            local enemyCenterY = y + 16
            if self:isValidSpawnPosition(enemyCenterX, enemyCenterY) then
                return x, y
            end
        end

    elseif shape.type == "line" then
        local maxAttempts = 10
        local minDistance = shape.minDistance or 100 -- Default minimum distance

        for attempt = 1, maxAttempts do
            local halfLength = shape.length / 2
            local x = playerX + math.random() * shape.length - halfLength

            -- Calculate Y position at minimum distance from player
            local distanceFromPlayer = math.sqrt((x - playerX)^2 + (0)^2)
            if distanceFromPlayer < minDistance then
                -- Adjust X to maintain minimum distance
                local direction = (x - playerX) / math.max(math.abs(x - playerX), 0.001)
                x = playerX + direction * minDistance
            end

            local y = playerY + (math.random() - 0.5) * 20

            local enemyCenterX = x + 16
            local enemyCenterY = y + 16
            if self:isValidSpawnPosition(enemyCenterX, enemyCenterY) then
                return x, y
            end
        end


    elseif shape.type == "rectangle" then
        local maxAttempts = 10
        for attempt = 1, maxAttempts do
            local x = playerX + math.random() * shape.width - shape.width / 2
            local y = playerY + math.random() * shape.height - shape.height / 2

            local enemyCenterX = x + 16
            local enemyCenterY = y + 16
            if self:isValidSpawnPosition(enemyCenterX, enemyCenterY) then
                return x, y
            end
        end


    else
        -- Default to circle with radius 200
        local angle = math.random() * 2 * math.pi
        local radius = math.random() * 200
        local x = playerX + math.cos(angle) * radius
        local y = playerY + math.sin(angle) * radius
        return x, y
    end
end

---Select an enemy type from the wave's enemy list
---@param wave table Wave definition
---@return string Enemy type
function EnemySpawnerSystem:selectEnemyType(wave)
    local totalCount = 0
    for _, enemy in ipairs(wave.enemies) do
        totalCount = totalCount + enemy.count
    end

    local randomValue = math.random() * totalCount
    local currentCount = 0

    for _, enemy in ipairs(wave.enemies) do
        currentCount = currentCount + enemy.count
        if randomValue <= currentCount then
            return enemy.type
        end
    end

    -- Fallback to first enemy type
    return wave.enemies[1].type
end

---Spawn an enemy of the specified type
---@param enemyType string Type of enemy to spawn
---@param x number X position
---@param y number Y position
---@return Entity|nil Spawned enemy entity or nil if failed
function EnemySpawnerSystem:spawnEnemy(enemyType, x, y)
    -- Safety check for valid coordinates
    if not x or not y then
        print(string.format("[EnemySpawnerSystem] Invalid coordinates: x=%s, y=%s", tostring(x), tostring(y)))
        return nil
    end

    local creator = nil

    if enemyType == "Slime" then
        creator = Slime and Slime.create
    elseif enemyType == "Skeleton" then
        creator = Skeleton and Skeleton.create
    elseif enemyType == "Warthog" then
        creator = Warthog and Warthog.create
    end

    if creator then
        return creator(x, y, self.ecsWorld, self.physicsWorld)
    else
        print(string.format("[EnemySpawnerSystem] WARNING: Unknown enemy type '%s'", enemyType))
        return nil
    end
end

---Check if a spawn position is valid (on solid ground)
---@param x number X position
---@param y number Y position
---@return boolean True if position is valid for spawning
function EnemySpawnerSystem:isValidSpawnPosition(x, y)
    if not self.ecsWorld then
        print("[EnemySpawnerSystem] No ECS world available for validation")
        return false
    end

    -- Find the pathfinding system to access the grid
    local pathfindingSystem = nil
    for _, system in ipairs(self.ecsWorld.systems) do
        -- Look for a system that has a grid property (PathfindingSystem has this)
        if system.grid and system.worldWidth and system.worldHeight then
            pathfindingSystem = system
            break
        end
    end

    if not pathfindingSystem then
        print("[EnemySpawnerSystem] PathfindingSystem not found in ECS world")
        return false -- Can't validate without pathfinding system
    end

    if not pathfindingSystem.grid then
        print("[EnemySpawnerSystem] PathfindingSystem grid not initialized")
        return false -- Can't validate without pathfinding grid
    end

    local CoordinateUtils = require("src.utils.coordinates")
    local gridX, gridY = CoordinateUtils.worldToGrid(x, y)

    local isInBounds = gridX >= 1 and gridX <= pathfindingSystem.worldWidth and
                      gridY >= 1 and gridY <= pathfindingSystem.worldHeight

    if not isInBounds then
        return false
    end

    local isWalkable = pathfindingSystem.grid:isWalkableAt(gridX, gridY, 1, 1)
    return isWalkable
end

---Find the player entity
---@return Entity|nil Player entity or nil if not found
function EnemySpawnerSystem:findPlayer()
    if not self.ecsWorld then return nil end

    for _, entity in ipairs(self.ecsWorld.entities) do
        if entity:hasTag("Player") then
            return entity
        end
    end

    return nil
end

---Update the enemy spawner system
---@param dt number Delta time
function EnemySpawnerSystem:update(dt)
    if not self.ecsWorld or not self.physicsWorld then return end

    local activeWave, waveIndex = self:getActiveWave()
    if not activeWave then
        self.spawnTimer = 0
        return
    end

    -- Update current wave index
    if waveIndex and waveIndex ~= self.currentWaveIndex then
        self.currentWaveIndex = waveIndex
        self.spawnTimer = 0
        print(string.format("[EnemySpawnerSystem] Wave %d started", waveIndex))
    end

    -- Find player for spawn positioning
    local player = self:findPlayer()
    if not player then return end

    local position = player:getComponent("Position")
    if not position then return end

    -- Update spawn timer
    self.spawnTimer = self.spawnTimer + dt

    -- Check if it's time to spawn
    local timeSinceLastSpawn = GameTimeManager.getTime() - self.lastSpawnTime
    if timeSinceLastSpawn >= (1.0 / activeWave.spawnRate) then
        -- Select enemy type
        local enemyType = self:selectEnemyType(activeWave)

        -- Calculate spawn position
        local spawnX, spawnY = self:calculateSpawnPosition(activeWave.shape, position.x, position.y)

        -- Only spawn if we got valid coordinates
        if spawnX and spawnY then
            -- Spawn enemy
            local enemy = self:spawnEnemy(enemyType, spawnX, spawnY)
            if enemy then
                self.lastSpawnTime = GameTimeManager.getTime()
                print(string.format("[EnemySpawnerSystem] Spawned %s at (%.1f, %.1f)", enemyType, spawnX, spawnY))
            end
        else
            print(string.format("[EnemySpawnerSystem] Failed to find valid spawn position for %s", enemyType))
        end
    end
end

return EnemySpawnerSystem
