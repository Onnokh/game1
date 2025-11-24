local System = require("src.core.System")
local EntityUtils = require("src.utils.entities")

---@class AbilitySystem : System
---Handles ability switching (Attack component cooldown is managed by AttackSystem)
local AbilitySystem = System:extend("AbilitySystem", {"Ability"})

-- Store the original new function
local originalNew = AbilitySystem.new

---Create a new AbilitySystem instance
---@return AbilitySystem
function AbilitySystem.new()
    local self = originalNew()
    self.lastAbilitySwitchTime = 0
    self.abilitySwitchCooldown = 0.2 -- Prevent rapid switching
    self.pendingAttackClear = false -- Flag to clear attack input after one frame
    return self
end

---Update all entities with Ability components
---@param dt number Delta time
function AbilitySystem:update(dt)
    local currentTime = love.timer.getTime()

    -- Clear attack flag from previous frame if it was set by action bar
    if self.pendingAttackClear then
        local GameState = require("src.core.GameState")
        if GameState and GameState.input then
            GameState.input.attack = false
        end
        self.pendingAttackClear = false
    end

    for _, entity in ipairs(self.entities) do
        local ability = entity:getComponent("Ability")

        if ability then
            -- Handle ability switching input for player
            if EntityUtils.isPlayer(entity) then
                -- Handle action bar slot presses first
                if self:handleActionBarSlotPress(entity, ability) then
                    -- Action bar slot was pressed and handled, skip normal switching
                else
                    self:handlePlayerAbilitySwitch(entity, ability, currentTime)
                end
            end
        end
    end
end

---Handle action bar slot key presses (Q-E-R-F)
---@param entity Entity The player entity
---@param ability Ability The ability component
---@return boolean True if a slot was pressed and handled
function AbilitySystem:handleActionBarSlotPress(entity, ability)
    local GameState = require("src.core.GameState")
    if not GameState or not GameState.input then
        return false
    end

    local slot = GameState.input.actionBarSlot
    if not slot or slot < 1 or slot > 4 then
        return false
    end

    -- Map slots to ability IDs
    -- Slot 1 (Q) = "ranged"
    -- Slots 2-4 (E-R-F) are empty for now
    local slotToAbility = {
        [1] = "ranged",
        [2] = nil,  -- Empty slot
        [3] = nil,  -- Empty slot
        [4] = nil   -- Empty slot
    }

    local abilityId = slotToAbility[slot]
    if not abilityId then
        -- Slot is empty, do nothing
        GameState.input.actionBarSlot = nil
        return true
    end

    -- Check if player has this ability
    if not ability:hasAbility(abilityId) then
        GameState.input.actionBarSlot = nil
        return true
    end

    -- Switch to the ability
    local switched = ability:switchTo(abilityId)
    if switched then
        -- Trigger an attack by setting attack input
        -- This will be processed by AttackSystem in the same update cycle
        GameState.input.attack = true
        -- Mark that we need to clear the attack flag after one frame
        self.pendingAttackClear = true
    end

    -- Clear the slot press (one-time trigger)
    GameState.input.actionBarSlot = nil
    return true
end

---Handle ability switching input for the player
---@param entity Entity The player entity
---@param ability Ability The ability component
---@param currentTime number Current game time
function AbilitySystem:handlePlayerAbilitySwitch(entity, ability, currentTime)
    -- Check for ability switch cooldown
    if (currentTime - self.lastAbilitySwitchTime) < self.abilitySwitchCooldown then
        return
    end

    -- Get input state from game state
    local GameState = require("src.core.GameState")
    if not GameState or not GameState.input then
        return
    end

    -- Check if ability switch was triggered
    if GameState.input.switchAbility then
        self:switchAbility(entity, nil) -- nil = switch to next ability
    end
end

---Switch ability for an entity
---@param entity Entity The entity to switch ability for
---@param abilityId string|nil The ability ID to switch to, or nil to switch to next
---@return boolean True if switch was successful
function AbilitySystem:switchAbility(entity, abilityId)
    local ability = entity:getComponent("Ability")
    if not ability then
        return false
    end

    local success = false
    local newAbilityId = nil

    if abilityId then
        success = ability:switchTo(abilityId)
        newAbilityId = abilityId
    else
        newAbilityId = ability:switchNext()
        success = newAbilityId ~= nil
    end

    if success then
        self.lastAbilitySwitchTime = love.timer.getTime()
    end

    return success
end

---Get the ability system singleton (for external access)
---@param world World The ECS world
---@return AbilitySystem|nil The ability system instance
function AbilitySystem.getInstance(world)
    if not world then
        return nil
    end

    for _, system in ipairs(world.systems) do
        if system.name == "AbilitySystem" then
            return system
        end
    end

    return nil
end

return AbilitySystem

