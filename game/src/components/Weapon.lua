local Component = require("src.core.Component")

---@class Weapon : Component
---@field currentWeapon string Currently equipped weapon ID
---@field inventory table<string, WeaponData> Available weapons by ID (immutable base definitions)
---@field weaponOverrides table<string, table> Per-weapon stat overrides (e.g., {ranged = {piercing = true}})
---@field canSwitch boolean Whether weapon switching is allowed
local Weapon = {}
Weapon.__index = Weapon

---@class WeaponData
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

---Create a new Weapon component
---@param currentWeapon string Starting weapon ID
---@param inventory table<string, WeaponData> Available weapons
---@return Component|Weapon
function Weapon.new(currentWeapon, inventory)
    local self = setmetatable(Component.new("Weapon"), Weapon)

    self.currentWeapon = currentWeapon or "ranged"
    self.inventory = inventory or {}
    self.weaponOverrides = {} -- Per-weapon stat overrides
    self.canSwitch = true

    return self
end

---Switch to a specific weapon
---@param weaponId string The weapon ID to switch to
---@return boolean True if switch was successful
function Weapon:switchTo(weaponId)
    if not self.canSwitch then
        return false
    end

    if self.inventory[weaponId] then
        self.currentWeapon = weaponId
        return true
    end

    return false
end

---Switch to the next weapon in inventory
---@return string|nil The new weapon ID, or nil if no switch occurred
function Weapon:switchNext()
    if not self.canSwitch then
        return nil
    end

    -- Get sorted list of weapon IDs
    local weaponIds = {}
    for id, _ in pairs(self.inventory) do
        table.insert(weaponIds, id)
    end
    table.sort(weaponIds)

    if #weaponIds <= 1 then
        return nil -- No other weapons to switch to
    end

    -- Find current weapon index
    local currentIndex = 1
    for i, id in ipairs(weaponIds) do
        if id == self.currentWeapon then
            currentIndex = i
            break
        end
    end

    -- Switch to next weapon (wrap around)
    local nextIndex = (currentIndex % #weaponIds) + 1
    self.currentWeapon = weaponIds[nextIndex]

    return self.currentWeapon
end

---Get the current weapon data with overrides applied
---@return WeaponData|nil The current weapon data merged with any overrides
function Weapon:getCurrentWeapon()
    local baseWeapon = self.inventory[self.currentWeapon]
    if not baseWeapon then
        return nil
    end

    -- If no overrides for this weapon, return base weapon directly
    local overrides = self.weaponOverrides[self.currentWeapon]
    if not overrides or next(overrides) == nil then
        return baseWeapon
    end

    -- Merge base weapon with overrides (shallow copy with overrides applied)
    local effectiveWeapon = {}
    for key, value in pairs(baseWeapon) do
        effectiveWeapon[key] = value
    end
    for key, value in pairs(overrides) do
        effectiveWeapon[key] = value
    end

    return effectiveWeapon
end

---Add a weapon to inventory
---@param weaponId string Weapon ID
---@param weaponData WeaponData Weapon stats
function Weapon:addWeapon(weaponId, weaponData)
    self.inventory[weaponId] = weaponData
end

---Remove a weapon from inventory
---@param weaponId string Weapon ID to remove
---@return boolean True if weapon was removed
function Weapon:removeWeapon(weaponId)
    if self.inventory[weaponId] and weaponId ~= self.currentWeapon then
        self.inventory[weaponId] = nil
        return true
    end
    return false
end

---Check if a weapon exists in inventory
---@param weaponId string Weapon ID to check
---@return boolean True if weapon exists
function Weapon:hasWeapon(weaponId)
    return self.inventory[weaponId] ~= nil
end

---Get list of all weapon IDs in inventory
---@return string[] Array of weapon IDs
function Weapon:getWeaponList()
    local weapons = {}
    for id, _ in pairs(self.inventory) do
        table.insert(weapons, id)
    end
    return weapons
end

---Set an override for a specific weapon stat
---@param weaponId string The weapon ID (e.g., "melee", "ranged")
---@param statName string The stat to override (e.g., "piercing", "damage")
---@param value any The value to set
function Weapon:setWeaponOverride(weaponId, statName, value)
    if not self.weaponOverrides[weaponId] then
        self.weaponOverrides[weaponId] = {}
    end
    self.weaponOverrides[weaponId][statName] = value
    print(string.format("[Weapon] Set override for %s.%s = %s", weaponId, statName, tostring(value)))
end

---Get an override value for a specific weapon stat
---@param weaponId string The weapon ID
---@param statName string The stat name
---@return any|nil The override value, or nil if not set
function Weapon:getWeaponOverride(weaponId, statName)
    if not self.weaponOverrides[weaponId] then
        return nil
    end
    return self.weaponOverrides[weaponId][statName]
end

---Serialize the Weapon component for saving
---@return table Serialized weapon data
function Weapon:serialize()
    return {
        currentWeapon = self.currentWeapon,
        inventory = self.inventory,
        weaponOverrides = self.weaponOverrides,
        canSwitch = self.canSwitch
    }
end

---Deserialize Weapon component from saved data
---@param data table Serialized weapon data
---@return Weapon Recreated Weapon component
function Weapon.deserialize(data)
    local weapon = Weapon.new(data.currentWeapon, data.inventory)
    weapon.weaponOverrides = data.weaponOverrides or {}
    weapon.canSwitch = data.canSwitch ~= false
    return weapon
end

return Weapon

