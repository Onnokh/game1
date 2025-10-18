local Component = require("src.core.Component")

---@class Weapon : Component
---@field currentWeapon string Currently equipped weapon ID
---@field inventory table<string, WeaponData> Available weapons by ID
---@field canSwitch boolean Whether weapon switching is allowed
local Weapon = {}
Weapon.__index = Weapon

---@class WeaponData
---@field name string Display name
---@field type string Attack type ("melee" or "ranged")
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

    self.currentWeapon = currentWeapon or "melee"
    self.inventory = inventory or {}
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

---Get the current weapon data
---@return WeaponData|nil The current weapon data
function Weapon:getCurrentWeapon()
    return self.inventory[self.currentWeapon]
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

---Serialize the Weapon component for saving
---@return table Serialized weapon data
function Weapon:serialize()
    return {
        currentWeapon = self.currentWeapon,
        inventory = self.inventory,
        canSwitch = self.canSwitch
    }
end

---Deserialize Weapon component from saved data
---@param data table Serialized weapon data
---@return Weapon Recreated Weapon component
function Weapon.deserialize(data)
    local weapon = Weapon.new(data.currentWeapon, data.inventory)
    weapon.canSwitch = data.canSwitch ~= false
    return weapon
end

return Weapon

