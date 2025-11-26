---@class PlayerStatDefinition
---@field baseValue number Base value at level 1
---@field perLevel number|nil Growth per level (additive, optional)
---@field perLevelMultiplier number|nil Growth per level (multiplicative, optional)

---Table of all player stat definitions
---Base stats represent level 1 values
---Level scaling can be additive (perLevel) or multiplicative (perLevelMultiplier)
---@type table<string, PlayerStatDefinition>
local playerStats = {
    max_health = {
        baseValue = 100,
        perLevel = 10  -- +10 health per level
    },
    max_mana = {
        baseValue = 80,
        perLevel = 5   -- +5 mana per level
    },
    movement_speed = {
        baseValue = 80,
        perLevel = 2   -- +2 speed per level
    },
    mana_recovery = {
        baseValue = 10,  -- per 5 seconds
        perLevel = 1     -- +1 mana recovery per level
    },
    dash_max_charges = {
        baseValue = 3,
        perLevel = nil   -- No level scaling (upgrades only)
    },
    dash_charge_regen_time = {
        baseValue = 2.0,  -- seconds
        perLevel = -0.05  -- -0.05 seconds per level (faster regen)
    },
    dash_duration = {
        baseValue = 0.25,  -- seconds
        perLevel = nil     -- No level scaling
    }
}

---Get base stat value (level 1)
---@param statName string Stat name
---@return number|nil Base value or nil if not found
local function getBaseStat(statName)
    local stat = playerStats[statName]
    return stat and stat.baseValue or nil
end

---Calculate stat value at a given level
---@param statName string Stat name
---@param level number Player level (1-based)
---@return number|nil Calculated stat value or nil if not found
local function getStatAtLevel(statName, level)
    local stat = playerStats[statName]
    if not stat then
        return nil
    end

    local value = stat.baseValue
    if level > 1 then
        local levelsAboveBase = level - 1
        
        -- Apply additive scaling
        if stat.perLevel then
            value = value + (stat.perLevel * levelsAboveBase)
        end
        
        -- Apply multiplicative scaling (if both exist, multiplicative is applied after additive)
        if stat.perLevelMultiplier then
            value = value * (stat.perLevelMultiplier ^ levelsAboveBase)
        end
    end

    return value
end

---Get all stat definitions
---@return table<string, PlayerStatDefinition>
local function getAllStats()
    return playerStats
end

---Check if a stat exists
---@param statName string Stat name
---@return boolean True if stat exists
local function hasStat(statName)
    return playerStats[statName] ~= nil
end

return {
    playerStats = playerStats,
    getBaseStat = getBaseStat,
    getStatAtLevel = getStatAtLevel,
    getAllStats = getAllStats,
    hasStat = hasStat
}

