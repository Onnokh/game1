---@class MobManager
---Handles mob spawning for both initial map load and phase-based spawning
local MobManager = {}

-- Internal state
MobManager.mobSpawnAreas = {} -- Store MobSpawn areas for dynamic spawning

-- Lazy-loaded monster modules
local Slime = nil
local Skeleton = nil
local Warhog = nil

---Initialize and lazy-load monster modules
local function loadMonsterModules()
    if not Slime then
        Slime = require("src.entities.Monsters.Slime.Slime")
    end
    if not Skeleton then
        Skeleton = require("src.entities.Monsters.Skeleton.Skeleton")
    end
    if not Warhog then
        Warhog = require("src.entities.Monsters.Warhog.Warhog")
    end
end

---Get monster creator function by type
---@param enemyType string Enemy type (e.g., "slime", "skeleton", "warhog")
---@return function|nil Creator function or nil if unknown type
local function getMonsterCreator(enemyType)
    loadMonsterModules()

    local creators = {
        slime = Slime and Slime.create or nil,
        skeleton = Skeleton and Skeleton.create or nil,
        warhog = Warhog and Warhog.create or nil
    }

    return creators[enemyType]
end

---Spawn random enemies in a specified area
---@param x number X position of spawn area (world coords)
---@param y number Y position of spawn area (world coords)
---@param width number Width of spawn area
---@param height number Height of spawn area
---@param amount number Number of enemies to spawn
---@param islandDef table Island definition with enemyTypes
---@param ecsWorld World ECS world
---@param physicsWorld love.World Physics world
---@param tagToAdd string|nil Optional tag to add to spawned enemies
---@param ignoreSpawnFlag boolean|nil If true, bypass enemySpawns safety check (for phases)
---@return number Number of enemies spawned
function MobManager.spawnEnemiesInArea(x, y, width, height, amount, islandDef, ecsWorld, physicsWorld, tagToAdd, ignoreSpawnFlag)
    -- Only check spawn flag for immediate spawns, not phase-based spawns
    if not ignoreSpawnFlag and (not islandDef.properties or not islandDef.properties.enemySpawns) then
        print(string.format("[MobManager] Skipping spawn - enemy spawns disabled for island: %s",
            islandDef.name or "unknown"))
        return 0
    end

    -- Get available enemy types from island definition
    local enemyTypes = islandDef.properties.enemyTypes or {"slime", "skeleton"}

    local safetyInfo = ""
    if ignoreSpawnFlag then
        safetyInfo = " | [FORCED SPAWN - Ignoring safety]"
    end

    print(string.format("[MobManager] Spawning %d enemies at (%.0f, %.0f) [%dx%d area] | Island: %s | Types: [%s]%s%s",
        amount, x, y, width, height,
        islandDef.name or "unknown",
        table.concat(enemyTypes, ", "),
        tagToAdd and " | Tag: " .. tagToAdd or "",
        safetyInfo))

    local spawnedCount = 0
    local spawnedTypes = {}

    for i = 1, amount do
        -- Pick random enemy type
        local enemyType = enemyTypes[math.random(1, #enemyTypes)]
        local creator = getMonsterCreator(enemyType)

        if creator then
            -- Pick random position within spawn area
            local spawnX = x + math.random() * width
            local spawnY = y + math.random() * height

            local enemy = creator(spawnX, spawnY, ecsWorld, physicsWorld)

            -- Add tag if specified (e.g., "SiegeAttacker")
            if enemy and tagToAdd and enemy.addTag then
                enemy:addTag(tagToAdd)
            end

            spawnedCount = spawnedCount + 1
            spawnedTypes[enemyType] = (spawnedTypes[enemyType] or 0) + 1

            print(string.format("  [MobManager] → Spawned %s #%d at (%.0f, %.0f)",
                enemyType, spawnedCount, spawnX, spawnY))
        else
            print(string.format("[MobManager] WARNING: Unknown enemy type '%s'", enemyType))
        end
    end

    if spawnedCount > 0 then
        local typesSummary = {}
        for type, count in pairs(spawnedTypes) do
            table.insert(typesSummary, string.format("%dx %s", count, type))
        end
        print(string.format("[MobManager] ✓ Spawned %d enemies: %s",
            spawnedCount, table.concat(typesSummary, ", ")))
    end

    return spawnedCount
end

---Register a MobSpawn area for later use
---@param spawnArea table Spawn area data {x, y, width, height, amount, phase, islandDef}
function MobManager.registerSpawnArea(spawnArea)
    table.insert(MobManager.mobSpawnAreas, spawnArea)

    local phaseInfo = spawnArea.phase and string.format(" [Phase: %s]", spawnArea.phase) or " [Immediate]"
    print(string.format("[MobManager] Registered spawn area #%d: %d enemies at (%.0f, %.0f)%s",
        #MobManager.mobSpawnAreas, spawnArea.amount, spawnArea.x, spawnArea.y, phaseInfo))
end

---Spawn enemies from MobSpawn areas that don't have a phase (immediate spawning)
---@param ecsWorld World ECS world
---@param physicsWorld love.World Physics world
---@return number Number of enemies spawned
function MobManager.spawnImmediateEnemies(ecsWorld, physicsWorld)
    if not ecsWorld or not physicsWorld then
        return 0
    end

    print("[MobManager] ===== IMMEDIATE ENEMY SPAWNING =====")

    local totalSpawned = 0
    local areasProcessed = 0

    -- Find all MobSpawn areas without a phase property
    for _, spawnArea in ipairs(MobManager.mobSpawnAreas) do
        if not spawnArea.phase then
            areasProcessed = areasProcessed + 1
            local spawned = MobManager.spawnEnemiesInArea(
                spawnArea.x,
                spawnArea.y,
                spawnArea.width,
                spawnArea.height,
                spawnArea.amount,
                spawnArea.islandDef,
                ecsWorld,
                physicsWorld,
                nil, -- No tag for immediate spawns
                false -- Respect enemySpawns flag for immediate spawns
            )

            totalSpawned = totalSpawned + spawned
        end
    end

    if totalSpawned > 0 then
        print(string.format("[MobManager] ===== IMMEDIATE SPAWN COMPLETE: %d enemies from %d areas =====",
            totalSpawned, areasProcessed))
    else
        print("[MobManager] ===== NO IMMEDIATE SPAWNS (all areas are phase-based) =====")
    end

    return totalSpawned
end

---Spawn enemies from MobSpawn areas for a specific phase
---@param phaseName string Phase name (e.g., "Siege")
---@param ecsWorld World ECS world
---@param physicsWorld love.World Physics world
---@param tagToAdd string|nil Optional tag to add to spawned enemies (e.g., "SiegeAttacker")
---@return number Number of enemies spawned
function MobManager.spawnPhaseEnemies(phaseName, ecsWorld, physicsWorld, tagToAdd)
    if not ecsWorld or not physicsWorld then
        return 0
    end

    print(string.format("[MobManager] ===== PHASE ENEMY SPAWNING: %s =====", phaseName))

    local totalSpawned = 0
    local areasProcessed = 0

    -- Find all MobSpawn areas for this phase
    for _, spawnArea in ipairs(MobManager.mobSpawnAreas) do
        if spawnArea.phase == phaseName then
            areasProcessed = areasProcessed + 1
            local spawned = MobManager.spawnEnemiesInArea(
                spawnArea.x,
                spawnArea.y,
                spawnArea.width,
                spawnArea.height,
                spawnArea.amount,
                spawnArea.islandDef,
                ecsWorld,
                physicsWorld,
                tagToAdd,
                true -- Ignore enemySpawns flag for phase-based spawns (Siege can attack anywhere!)
            )

            totalSpawned = totalSpawned + spawned
        end
    end

    if totalSpawned > 0 then
        print(string.format("[MobManager] ===== %s PHASE SPAWN COMPLETE: %d enemies from %d areas =====",
            phaseName, totalSpawned, areasProcessed))
    else
        print(string.format("[MobManager] ===== NO SPAWNS FOR %s PHASE (no areas configured) =====", phaseName))
    end

    return totalSpawned
end

---Get all MobSpawn areas for a specific phase
---@param phaseName string|nil Phase name (e.g., "Siege"), or nil for all
---@return table Array of spawn areas
function MobManager.getSpawnAreas(phaseName)
    if not phaseName then
        return MobManager.mobSpawnAreas
    end

    local filtered = {}
    for _, area in ipairs(MobManager.mobSpawnAreas) do
        if area.phase == phaseName then
            table.insert(filtered, area)
        end
    end
    return filtered
end

---Clear all registered spawn areas (called on map unload)
function MobManager.clear()
    local count = #MobManager.mobSpawnAreas
    MobManager.mobSpawnAreas = {}
    print(string.format("[MobManager] Cleared %d spawn areas", count))
end

return MobManager

