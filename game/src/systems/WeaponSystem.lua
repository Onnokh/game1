local System = require("src.core.System")
local EntityUtils = require("src.utils.entities")

---@class WeaponSystem : System
---Handles weapon switching (Attack component cooldown is managed by AttackSystem)
local WeaponSystem = System:extend("WeaponSystem", {"Weapon"})

-- Store the original new function
local originalNew = WeaponSystem.new

---Create a new WeaponSystem instance
---@return WeaponSystem
function WeaponSystem.new()
    local self = originalNew()
    self.lastWeaponSwitchTime = 0
    self.weaponSwitchCooldown = 0.2 -- Prevent rapid switching
    return self
end

---Update all entities with Weapon components
---@param dt number Delta time
function WeaponSystem:update(dt)
    local currentTime = love.timer.getTime()

    for _, entity in ipairs(self.entities) do
        local weapon = entity:getComponent("Weapon")

        if weapon then
            -- Handle weapon switching input for player
            if EntityUtils.isPlayer(entity) then
                self:handlePlayerWeaponSwitch(entity, weapon, currentTime)
            end
        end
    end
end

---Handle weapon switching input for the player
---@param entity Entity The player entity
---@param weapon Weapon The weapon component
---@param currentTime number Current game time
function WeaponSystem:handlePlayerWeaponSwitch(entity, weapon, currentTime)
    -- Check for weapon switch cooldown
    if (currentTime - self.lastWeaponSwitchTime) < self.weaponSwitchCooldown then
        return
    end

    -- Get input state from game state
    local GameState = require("src.core.GameState")
    if not GameState or not GameState.input then
        return
    end

    -- Check if weapon switch was triggered
    if GameState.input.switchWeapon then
        self:switchWeapon(entity, nil) -- nil = switch to next weapon
    end
end

---Switch weapon for an entity
---@param entity Entity The entity to switch weapon for
---@param weaponId string|nil The weapon ID to switch to, or nil to switch to next
---@return boolean True if switch was successful
function WeaponSystem:switchWeapon(entity, weaponId)
    local weapon = entity:getComponent("Weapon")
    if not weapon then
        return false
    end

    local success = false
    local newWeaponId = nil

    if weaponId then
        success = weapon:switchTo(weaponId)
        newWeaponId = weaponId
    else
        newWeaponId = weapon:switchNext()
        success = newWeaponId ~= nil
    end

    if success then
        self.lastWeaponSwitchTime = love.timer.getTime()
    end

    return success
end

---Get the weapon system singleton (for external access)
---@param world World The ECS world
---@return WeaponSystem|nil The weapon system instance
function WeaponSystem.getInstance(world)
    if not world then
        return nil
    end

    for _, system in ipairs(world.systems) do
        if system.name == "WeaponSystem" then
            return system
        end
    end

    return nil
end

return WeaponSystem

