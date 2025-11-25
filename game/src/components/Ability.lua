local Component = require("src.core.Component")

---@class Ability : Component
---@field currentAbility string Currently equipped ability ID
---@field inventory table<string, AbilityData> Available abilities by ID (immutable base definitions)
---@field abilityOverrides table<string, table> Per-ability stat overrides (e.g., {lightningbolt = {piercing = true}})
---@field canSwitch boolean Whether ability switching is allowed
local Ability = {}
Ability.__index = Ability

---@class AbilityData
---@field name string Display name
---@field type string Attack type ("ranged")
---@field damage number Damage dealt
---@field range number Range (melee range or bullet range)
---@field cooldown number Time between attacks
---@field knockback number Knockback force applied to targets
---@field recoilKnockback number|nil Knockback force applied to shooter when firing
---@field bulletSpeed number|nil Speed of bullets (ranged only)
---@field bulletLifetime number|nil Lifetime of bullets in seconds (ranged only)
---@field piercing boolean|nil Can bullet pierce through enemies (ranged only)
---@field glowColor table|nil RGB color for bullet glow {r, g, b} (0-1 range)

---Create a new Ability component
---@param currentAbility string Starting ability ID
---@param inventory table<string, AbilityData> Available abilities
---@return Component|Ability
function Ability.new(currentAbility, inventory)
    local self = setmetatable(Component.new("Ability"), Ability)

    self.currentAbility = currentAbility or "lightningbolt"
    self.inventory = inventory or {}
    self.abilityOverrides = {} -- Per-ability stat overrides
    self.canSwitch = true

    return self
end

---Switch to a specific ability
---@param abilityId string The ability ID to switch to
---@return boolean True if switch was successful
function Ability:switchTo(abilityId)
    if not self.canSwitch then
        return false
    end

    if self.inventory[abilityId] then
        self.currentAbility = abilityId
        return true
    end

    return false
end

---Switch to the next ability in inventory
---@return string|nil The new ability ID, or nil if no switch occurred
function Ability:switchNext()
    if not self.canSwitch then
        return nil
    end

    -- Get sorted list of ability IDs
    local abilityIds = {}
    for id, _ in pairs(self.inventory) do
        table.insert(abilityIds, id)
    end
    table.sort(abilityIds)

    if #abilityIds <= 1 then
        return nil -- No other abilities to switch to
    end

    -- Find current ability index
    local currentIndex = 1
    for i, id in ipairs(abilityIds) do
        if id == self.currentAbility then
            currentIndex = i
            break
        end
    end

    -- Switch to next ability (wrap around)
    local nextIndex = (currentIndex % #abilityIds) + 1
    self.currentAbility = abilityIds[nextIndex]

    return self.currentAbility
end

---Get the current ability data with overrides applied
---@return AbilityData|nil The current ability data merged with any overrides
function Ability:getCurrentAbility()
    local baseAbility = self.inventory[self.currentAbility]
    if not baseAbility then
        return nil
    end

    -- If no overrides for this ability, return base ability directly
    local overrides = self.abilityOverrides[self.currentAbility]
    if not overrides or next(overrides) == nil then
        return baseAbility
    end

    -- Merge base ability with overrides (shallow copy with overrides applied)
    local effectiveAbility = {}
    for key, value in pairs(baseAbility) do
        effectiveAbility[key] = value
    end
    for key, value in pairs(overrides) do
        effectiveAbility[key] = value
    end

    return effectiveAbility
end

---Add an ability to inventory
---@param abilityId string Ability ID
---@param abilityData AbilityData Ability stats
function Ability:addAbility(abilityId, abilityData)
    self.inventory[abilityId] = abilityData
end

---Remove an ability from inventory
---@param abilityId string Ability ID to remove
---@return boolean True if ability was removed
function Ability:removeAbility(abilityId)
    if self.inventory[abilityId] and abilityId ~= self.currentAbility then
        self.inventory[abilityId] = nil
        return true
    end
    return false
end

---Check if an ability exists in inventory
---@param abilityId string Ability ID to check
---@return boolean True if ability exists
function Ability:hasAbility(abilityId)
    return self.inventory[abilityId] ~= nil
end

---Get list of all ability IDs in inventory
---@return string[] Array of ability IDs
function Ability:getAbilityList()
    local abilities = {}
    for id, _ in pairs(self.inventory) do
        table.insert(abilities, id)
    end
    return abilities
end

---Set an override for a specific ability stat
---@param abilityId string The ability ID (e.g., "melee", "lightningbolt")
---@param statName string The stat to override (e.g., "piercing", "damage")
---@param value any The value to set
function Ability:setAbilityOverride(abilityId, statName, value)
    if not self.abilityOverrides[abilityId] then
        self.abilityOverrides[abilityId] = {}
    end
    self.abilityOverrides[abilityId][statName] = value
    print(string.format("[Ability] Set override for %s.%s = %s", abilityId, statName, tostring(value)))
end

---Get an override value for a specific ability stat
---@param abilityId string The ability ID
---@param statName string The stat name
---@return any|nil The override value, or nil if not set
function Ability:getAbilityOverride(abilityId, statName)
    if not self.abilityOverrides[abilityId] then
        return nil
    end
    return self.abilityOverrides[abilityId][statName]
end

---Serialize the Ability component for saving
---@return table Serialized ability data
function Ability:serialize()
    return {
        currentAbility = self.currentAbility,
        inventory = self.inventory,
        abilityOverrides = self.abilityOverrides,
        canSwitch = self.canSwitch
    }
end

---Deserialize Ability component from saved data
---@param data table Serialized ability data
---@return Ability Recreated Ability component
function Ability.deserialize(data)
    local ability = Ability.new(data.currentAbility, data.inventory)
    ability.abilityOverrides = data.abilityOverrides or {}
    ability.canSwitch = data.canSwitch ~= false
    return ability
end

return Ability

