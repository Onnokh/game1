---@class SaveSystem
--- Complete save/load system with future-proof component serialization
--- Components can implement serialize()/deserialize() methods or be registered here
local SaveSystem = {}

-- Save file configuration
local SAVE_FILE = "savegame.lua"

-- Tracking for warnings and stats
SaveSystem.warnedComponents = {}
SaveSystem.skippedComponents = {}

-- Tags that should be saved (persistent entities)
local PERSISTENT_TAGS = {
    "Player", "Monster", "Coin",
    "Reactor", "Shop", "Tree", "SiegeAttacker"
}

-- Entity type to module path mapping (DRY approach)
local ENTITY_PATHS = {
    Player = "src.entities.Player.Player",
    Skeleton = "src.entities.Monsters.Skeleton.Skeleton",
    Slime = "src.entities.Monsters.Slime.Slime",
    Warthog = "src.entities.Monsters.Warthog.Warthog",
    Coin = "src.entities.Coin",
    Shop = "src.entities.Shop.Shop",
    Reactor = "src.entities.Reactor.Reactor",
    Tree = "src.entities.Decoration.Tree"
}

---Get entity factory function for a given entity type
---@param entityType string The entity type
---@return function|nil Factory function or nil if not found
function SaveSystem.getEntityFactory(entityType)
    local modulePath = ENTITY_PATHS[entityType]
    if not modulePath then
        return nil
    end

    local success, module = pcall(require, modulePath)
    if success and module and module.create then
        return module.create
    end

    print(string.format("[SaveSystem] ERROR: Module '%s' has no create() function", modulePath))
    return nil
end

-- Component Registry for components without serialize() methods
-- or for marking components as transient (persistent = false)
SaveSystem.componentRegistry = {
    -- Transient components (don't save, don't warn)
    Bullet = { persistent = false },
    AttackCollider = { persistent = false },
    DamageEvent = { persistent = false },
    FlashEffect = { persistent = false },
    ParticleSystem = { persistent = false },
    Knockback = { persistent = false }, -- Transient state

    -- Components with custom serialization can be added here if needed
    -- Most components should implement serialize() method instead
    -- (Attack, DropTable, Light, Interactable, Shop now have their own methods)
}

---Check if an entity should be saved based on its tags
---@param entity Entity
---@return boolean
local function shouldSaveEntity(entity)
    for _, tag in ipairs(PERSISTENT_TAGS) do
        if entity:hasTag(tag) then
            return true
        end
    end
    return false
end

---Serialize a component using priority: serialize() method > registry > skip with warning
---@param componentType string
---@param component table
---@return table|nil Serialized data or nil if skipped
function SaveSystem.serializeComponent(componentType, component)
    -- Priority 1: Check if component has serialize() method
    if type(component.serialize) == "function" then
        local success, result = pcall(component.serialize, component)
        if success then
            return result
        else
            print(string.format("[SaveSystem] ERROR: Component '%s' serialize() failed: %s", componentType, result))
            return nil
        end
    end

    -- Priority 2: Check registry
    local handler = SaveSystem.componentRegistry[componentType]
    if handler then
        if handler.persistent == false then
            -- Marked as transient, skip silently
            return nil
        end
        if handler.serialize then
            local success, result = pcall(handler.serialize, component)
            if success then
                return result
            else
                print(string.format("[SaveSystem] ERROR: Registry serializer for '%s' failed: %s", componentType, result))
                return nil
            end
        end
    end

    -- Priority 3: Unknown component - warn and skip
    if not SaveSystem.warnedComponents[componentType] then
        print(string.format("[SaveSystem] WARNING: Component '%s' has no serialization handler", componentType))
        print("  Add serialize() method to the component OR add to SaveSystem.componentRegistry")
        SaveSystem.warnedComponents[componentType] = true
    end
    SaveSystem.skippedComponents[componentType] = (SaveSystem.skippedComponents[componentType] or 0) + 1

    return nil
end

---Get entity type from tags for factory lookup
---@param entity Entity
---@return string Entity type name
function SaveSystem.getEntityType(entity)
    -- Check each registered entity type (single source of truth: ENTITY_PATHS)
    for entityType, _ in pairs(ENTITY_PATHS) do
        if entity:hasTag(entityType) then
            return entityType
        end
    end
    return "Unknown"
end

---Serialize an entity to a saveable table
---@param entity Entity
---@return table Serialized entity data
function SaveSystem.serializeEntity(entity)
    local data = {
        entityType = SaveSystem.getEntityType(entity), -- Identify which factory to use
        id = entity.id,
        tags = {},
        components = {}
    }

    -- Serialize tags
    for tag, _ in pairs(entity.tags) do
        table.insert(data.tags, tag)
    end

    -- Serialize each component
    for componentType, component in pairs(entity.components) do
        local serialized = SaveSystem.serializeComponent(componentType, component)
        if serialized then
            data.components[componentType] = serialized
        end
    end

    return data
end

---Serialize the complete game state
---@return table|nil Serialized game state or nil on error
function SaveSystem.serializeGameState()
    local GameState = require("src.core.GameState")
    local GameController = require("src.core.GameController")
    local GameScene = require("src.scenes.game")

    local ecsWorld = GameScene.ecsWorld
    if not ecsWorld then
        print("[SaveSystem] ERROR: Cannot save - ECS world not initialized")
        return nil
    end

    -- Reset stats tracking
    SaveSystem.skippedComponents = {}

    -- Get map seed from MapManager if available
    local MapManager = require("src.core.managers.MapManager")
    local mapSeed = MapManager.currentSeed or os.time()

    local saveData = {
        version = 1, -- Save format version for future compatibility
        timestamp = os.time(),

        -- Game progress
        gameState = {
            phase = GameState.phase or "Discovery",
            day = GameState.day or 1,
            coins = {
                total = GameState.coins.total or 0,
                collectedThisSession = GameState.coins.collectedThisSession or 0
            }
        },

        -- Controller state
        controller = {
            currentPhase = GameController.currentPhase or "Discovery"
        },

        -- Level/map information
        level = {
            name = "src/levels/level1", -- Currently hardcoded, expand later
            mapSeed = mapSeed -- Save the random seed used for map generation
        },

        -- Entities
        entities = {}
    }

    -- Serialize all persistent entities
    local savedCount = 0
    local skippedCount = 0
    local componentCount = 0

    for _, entity in ipairs(ecsWorld.entities) do
        if entity.active and shouldSaveEntity(entity) then
            local entityData = SaveSystem.serializeEntity(entity)
            table.insert(saveData.entities, entityData)
            savedCount = savedCount + 1

            -- Count components
            for _ in pairs(entityData.components) do
                componentCount = componentCount + 1
            end
        else
            skippedCount = skippedCount + 1
        end
    end

    -- Print summary
    print(string.format("[SaveSystem] Serialization complete:"))
    print(string.format("  Entities saved: %d", savedCount))
    print(string.format("  Entities skipped: %d (transient)", skippedCount))
    print(string.format("  Components serialized: %d", componentCount))

    local totalSkipped = 0
    for _, count in pairs(SaveSystem.skippedComponents) do
        totalSkipped = totalSkipped + count
    end

    if totalSkipped > 0 then
        print(string.format("  Components skipped: %d", totalSkipped))
        for componentType, count in pairs(SaveSystem.skippedComponents) do
            local handler = SaveSystem.componentRegistry[componentType]
            local reason = (handler and handler.persistent == false) and "(transient)" or "(no handler)"
            print(string.format("    - %s: %d instances %s", componentType, count, reason))
        end
    end

    return saveData
end

---Serialize a Lua table to a string
---@param tbl table The table to serialize
---@param indent number Current indentation level
---@return string Serialized string
local function tableToString(tbl, indent)
    indent = indent or 0
    local indentStr = string.rep("  ", indent)
    local lines = {}

    table.insert(lines, "{")

    for k, v in pairs(tbl) do
        local key
        if type(k) == "string" then
            -- Use bracket notation for string keys to handle special characters
            key = string.format('["%s"]', k)
        else
            key = string.format("[%s]", tostring(k))
        end

        local value
        if type(v) == "table" then
            value = tableToString(v, indent + 1)
        elseif type(v) == "string" then
            -- Escape quotes in strings
            value = string.format('"%s"', v:gsub('"', '\\"'))
        elseif type(v) == "boolean" then
            value = tostring(v)
        elseif type(v) == "number" then
            value = tostring(v)
        else
            value = "nil"
        end

        table.insert(lines, string.format("%s  %s = %s,", indentStr, key, value))
    end

    table.insert(lines, indentStr .. "}")

    return table.concat(lines, "\n")
end

---Save the current game state to disk
---@return boolean success True if save succeeded
function SaveSystem.save()
    print("[SaveSystem] Saving game...")

    local saveData = SaveSystem.serializeGameState()
    if not saveData then
        print("[SaveSystem] ERROR: Failed to serialize game state")
        return false
    end

    -- Serialize to Lua table string
    local serialized = "return " .. tableToString(saveData)

    -- Write to file
    local success, err = pcall(function()
        love.filesystem.write(SAVE_FILE, serialized)
    end)

    if success then
        local saveDir = love.filesystem.getSaveDirectory()
        print(string.format("[SaveSystem] Save complete: %s/%s", saveDir, SAVE_FILE))
        return true
    else
        print(string.format("[SaveSystem] ERROR: Failed to write save file: %s", err))
        return false
    end
end

---Check if a save file exists
---@return boolean exists True if save file exists
function SaveSystem.hasSave()
    local info = love.filesystem.getInfo(SAVE_FILE)
    return info ~= nil and info.type == "file"
end

---Delete the save file
---@return boolean success True if deletion succeeded
function SaveSystem.deleteSave()
    -- Clear any pending load data (important for New Game after Continue)
    SaveSystem.pendingLoadData = nil

    if not SaveSystem.hasSave() then
        return true
    end

    local success, err = pcall(function()
        love.filesystem.remove(SAVE_FILE)
    end)

    if success then
        print("[SaveSystem] Save file deleted")
        return true
    else
        print(string.format("[SaveSystem] ERROR: Failed to delete save file: %s", err))
        return false
    end
end

---Deserialize a component from saved data
---@param componentType string
---@param data table Serialized component data
---@return table|nil Component instance or nil on error
function SaveSystem.deserializeComponent(componentType, data)
    -- Try to load the component module
    local success, ComponentClass = pcall(require, "src.components." .. componentType)

    if not success then
        print(string.format("[SaveSystem] WARNING: Could not load component module: %s", componentType))
        return nil
    end

    -- Priority 1: Check if component has deserialize() static method
    if type(ComponentClass.deserialize) == "function" then
        local success, result = pcall(ComponentClass.deserialize, data)
        if success then
            return result
        else
            print(string.format("[SaveSystem] ERROR: Component '%s' deserialize() failed: %s", componentType, result))
            return nil
        end
    end

    -- Priority 2: Check registry
    local handler = SaveSystem.componentRegistry[componentType]
    if handler and handler.deserialize then
        local success, result = pcall(handler.deserialize, data)
        if success then
            return result
        else
            print(string.format("[SaveSystem] ERROR: Registry deserializer for '%s' failed: %s", componentType, result))
            return nil
        end
    end

    -- No deserializer found
    print(string.format("[SaveSystem] WARNING: Component '%s' has no deserialize() method", componentType))
    return nil
end

---Update entity components with saved values
---@param entity Entity The entity to update
---@param savedComponents table Table of saved component data
function SaveSystem.updateEntityComponents(entity, savedComponents)
    for componentType, savedData in pairs(savedComponents) do
        local component = entity:getComponent(componentType)
        if component then
            -- Update component fields from saved data
            for key, value in pairs(savedData) do
                -- Skip physics objects and functions
                if key ~= "collider" and key ~= "body" and key ~= "fixture" and
                   key ~= "physicsWorld" and key ~= "lightWorld" and
                   key ~= "pathfinder" and key ~= "grid" and
                   type(value) ~= "function" then
                    component[key] = value
                end
            end
        end
    end
end

---Recreate an entity from saved data using entity factories
---@param entityData table Serialized entity data
---@param ecsWorld World The ECS world
---@param physicsWorld love.World The physics world
---@return Entity|nil Recreated entity or nil on error
function SaveSystem.deserializeEntity(entityData, ecsWorld, physicsWorld)
    local entityType = entityData.entityType

    -- Validate entity type is registered
    if not ENTITY_PATHS[entityType] then
        print(string.format("[SaveSystem] ERROR: Unknown entity type '%s' - not in ENTITY_PATHS", entityType or "nil"))
        return nil
    end

    local factory = SaveSystem.getEntityFactory(entityType)

    if not factory then
        print(string.format("[SaveSystem] WARNING: No factory found for entity type '%s'", entityType))
        return nil
    end

    -- Extract position from saved data
    local posData = entityData.components.Position
    local x = posData and posData.x or 0
    local y = posData and posData.y or 0

    -- Use factory to create entity with all states, callbacks, and proper initialization
    local entity = factory(x, y, ecsWorld, physicsWorld)

    if entity then
        -- Restore additional tags from save (factory creates base tags, but save may have more)
        for _, tag in ipairs(entityData.tags) do
            if not entity:hasTag(tag) then
                entity:addTag(tag)
            end
        end

        -- Update component values from save data (overwrites factory defaults with saved state)
        SaveSystem.updateEntityComponents(entity, entityData.components)

        print(string.format("[SaveSystem] Restored %s at (%.0f, %.0f)", entityType, x, y))
    else
        print(string.format("[SaveSystem] ERROR: Factory failed to create %s", entityType))
    end

    return entity
end

---Load game state from disk
---@return boolean success True if load succeeded
function SaveSystem.load()
    print("[SaveSystem] Loading game...")

    if not SaveSystem.hasSave() then
        print("[SaveSystem] ERROR: No save file found")
        return false
    end

    -- Load and execute the save file
    local chunk, err = love.filesystem.load(SAVE_FILE)
    if not chunk then
        print(string.format("[SaveSystem] ERROR: Failed to load save file: %s", err))
        return false
    end

    local success, saveData = pcall(chunk)
    if not success then
        print(string.format("[SaveSystem] ERROR: Failed to parse save file: %s", saveData))
        return false
    end

    -- Validate save data
    if not saveData or not saveData.version or not saveData.entities then
        print("[SaveSystem] ERROR: Invalid save file format")
        return false
    end

    print(string.format("[SaveSystem] Loaded save version %d from %s", saveData.version, os.date("%c", saveData.timestamp)))

    -- Store save data for use during game scene load
    SaveSystem.pendingLoadData = saveData

    return true
end

---Get the map seed from pending save data (called before scene loads)
---@return number|nil The map seed or nil if no save data
function SaveSystem.getPendingMapSeed()
    if SaveSystem.pendingLoadData and SaveSystem.pendingLoadData.level then
        return SaveSystem.pendingLoadData.level.mapSeed
    end
    return nil
end

---Apply loaded save data to the game (called after scene loads)
---@param ecsWorld World The ECS world
---@param physicsWorld love.World The physics world
---@return boolean success True if restoration succeeded
function SaveSystem.restoreGameState(ecsWorld, physicsWorld)
    local saveData = SaveSystem.pendingLoadData
    if not saveData then
        print("[SaveSystem] ERROR: No pending save data to restore")
        return false
    end

    print("[SaveSystem] Restoring game state...")

    local GameState = require("src.core.GameState")
    local GameController = require("src.core.GameController")

    -- Restore game state
    GameState.phase = saveData.gameState.phase
    GameState.day = saveData.gameState.day
    GameState.coins = saveData.gameState.coins

    -- Restore controller state (set phase directly without triggering onEnter/onExit)
    local targetPhase = saveData.controller.currentPhase
    if GameController.currentPhase ~= targetPhase then
        print(string.format("[SaveSystem] Restoring phase to '%s' (without triggering phase transitions)", targetPhase))
        GameController.currentPhase = targetPhase
        GameState.phase = targetPhase

        -- Apply phase-specific ambient lighting without spawning entities
        local GameScene = require("src.scenes.game")
        if targetPhase == "Siege" and GameScene and GameScene.setAmbientColor then
            GameScene.setAmbientColor(70, 90, 140, 255, 0) -- Instant transition (0 duration)
        elseif targetPhase == "Discovery" and GameScene and GameScene.setAmbientColor then
            GameScene.setAmbientColor(255, 240, 255, 255, 0) -- Instant transition (0 duration)
        end
    end

    -- Clear existing entities (except those created by map)
    local entitiesToRemove = {}
    for _, entity in ipairs(ecsWorld.entities) do
        -- Keep map-generated entities that are deterministic (will regenerate same)
        -- Remove dynamic entities (player, monsters, coins) that we'll restore from save
        local keepEntity = entity:hasTag("Decoration") or
                          entity:hasTag("TileLight") or
                          entity:hasTag("GlobalParticles")

        if not keepEntity then
            table.insert(entitiesToRemove, entity)
        end
    end

    for _, entity in ipairs(entitiesToRemove) do
        ecsWorld:removeEntity(entity)
    end

    -- Recreate saved entities using factories (factories add entities to world automatically)
    local restoredCount = 0
    local restoredPlayer = nil

    for _, entityData in ipairs(saveData.entities) do
        local entity = SaveSystem.deserializeEntity(entityData, ecsWorld, physicsWorld)
        if entity then
            -- Entity is already added to world by factory, just count it
            restoredCount = restoredCount + 1

            -- Track player entity for game scene reference update
            if entity:hasTag("Player") then
                restoredPlayer = entity
            end
        end
    end

    print(string.format("[SaveSystem] Restored %d entities", restoredCount))

    -- Clear pending data
    SaveSystem.pendingLoadData = nil

    -- Return the restored player entity so GameScene can update its reference
    return true, restoredPlayer
end

return SaveSystem

