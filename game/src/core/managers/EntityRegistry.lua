---@class EntityRegistry
---Centralized registry for all entity types in the game
---Single source of truth for entity definitions, replacing duplicated registries
local EntityRegistry = {}

-- Entity definitions
-- Each entry maps:
-- - Capitalized tag name (used by SaveSystem) -> module path
-- - Lowercase spawn name (used by spawning systems) -> same entry
-- - Module path -> used to require and get factory
local ENTITY_REGISTRY = {
    -- Player
    Player = {
        tag = "Player",
        spawnName = "player", -- Not typically spawned, but for consistency
        modulePath = "src.entities.Player.Player"
    },

    -- Monsters
    Skeleton = {
        tag = "Skeleton",
        spawnName = "skeleton",
        modulePath = "src.entities.Monsters.Skeleton.Skeleton",
        configPath = "src.entities.Monsters.Skeleton.SkeletonConfig"
    },
    Slime = {
        tag = "Slime",
        spawnName = "slime",
        modulePath = "src.entities.Monsters.Slime.Slime",
        configPath = "src.entities.Monsters.Slime.SlimeConfig"
    },
    CragBoar = {
        tag = "CragBoar",
        spawnName = "cragboar",
        modulePath = "src.entities.Monsters.CragBoar.CragBoar",
        configPath = "src.entities.Monsters.CragBoar.CragBoarConfig"
    },
    Bear = {
        tag = "Bear",
        spawnName = "bear",
        modulePath = "src.entities.Monsters.Bear.Bear",
        configPath = "src.entities.Monsters.Bear.BearConfig"
    },

    -- Other entities
    Coin = {
        tag = "Coin",
        spawnName = "coin",
        modulePath = "src.entities.Coin"
    },
    Shop = {
        tag = "Shop",
        spawnName = "shop",
        modulePath = "src.entities.Shop.Shop"
    },
    Tree = {
        tag = "Tree",
        spawnName = "tree",
        modulePath = "src.entities.Decoration.Tree"
    },
    Crystal = {
        tag = "Crystal",
        spawnName = "crystal",
        modulePath = "src.entities.Crystal.Crystal"
    }
}

-- Cache for loaded modules and factories
local moduleCache = {}
local factoryCache = {}
local configCache = {}

---Get entity definition by capitalized tag name
---@param tag string Capitalized entity tag (e.g., "Skeleton")
---@return table|nil Entity definition or nil
function EntityRegistry.getByTag(tag)
    return ENTITY_REGISTRY[tag]
end

---Get entity definition by lowercase spawn name
---@param spawnName string Lowercase spawn name (e.g., "skeleton")
---@return table|nil Entity definition or nil
function EntityRegistry.getBySpawnName(spawnName)
    for _, def in pairs(ENTITY_REGISTRY) do
        if def.spawnName == spawnName then
            return def
        end
    end
    return nil
end

---Get entity factory function by capitalized tag name
---Used by SaveSystem for loading entities
---@param entityType string Capitalized entity tag (e.g., "Skeleton")
---@return function|nil Factory function or nil
function EntityRegistry.getEntityFactory(entityType)
    -- Check cache first
    if factoryCache[entityType] then
        return factoryCache[entityType]
    end

    local def = EntityRegistry.getByTag(entityType)
    if not def then
        return nil
    end

    -- Load module (use cache if available)
    local module
    if moduleCache[def.modulePath] then
        module = moduleCache[def.modulePath]
    else
        local success, loadedModule = pcall(require, def.modulePath)
        if not success or not loadedModule then
            print(string.format("[EntityRegistry] ERROR: Failed to load module '%s'", def.modulePath))
            return nil
        end
        module = loadedModule
        moduleCache[def.modulePath] = module
    end

    -- Get factory function
    if module and module.create then
        factoryCache[entityType] = module.create
        return module.create
    end

    print(string.format("[EntityRegistry] ERROR: Module '%s' has no create() function", def.modulePath))
    return nil
end

---Get monster factory and config by lowercase spawn name
---Used by spawning systems
---@param spawnName string Lowercase spawn name (e.g., "skeleton")
---@return function|nil factory Factory function or nil
---@return table|nil config Config table or nil
function EntityRegistry.getMonsterFactory(spawnName)
    local def = EntityRegistry.getBySpawnName(spawnName)
    if not def then
        return nil, nil
    end

    -- Get factory (use existing cache mechanism)
    local factory = EntityRegistry.getEntityFactory(def.tag)
    if not factory then
        return nil, nil
    end

    -- Get config if available (monsters have configs)
    local config = nil
    if def.configPath then
        if configCache[def.configPath] then
            config = configCache[def.configPath]
        else
            local success, loadedConfig = pcall(require, def.configPath)
            if success and loadedConfig then
                config = loadedConfig
                configCache[def.configPath] = config
            end
        end
    end

    return factory, config
end

---Get monster creator function by lowercase spawn name
---Used by MobManager for spawning
---@param spawnName string Lowercase spawn name (e.g., "skeleton")
---@return function|nil Creator function or nil
function EntityRegistry.getMonsterCreator(spawnName)
    local factory, _ = EntityRegistry.getMonsterFactory(spawnName)
    return factory
end

---Check if an entity type is registered
---@param entityType string Capitalized entity tag
---@return boolean
function EntityRegistry.isRegistered(entityType)
    return EntityRegistry.getByTag(entityType) ~= nil
end

---Get all registered entity tags
---@return table Array of entity tags
function EntityRegistry.getAllTags()
    local tags = {}
    for tag, _ in pairs(ENTITY_REGISTRY) do
        table.insert(tags, tag)
    end
    return tags
end

return EntityRegistry

