local System = require("src.core.System")
local EntityUtils = require("src.utils.entities")

---@class AbilitySystem : System
---Handles ability switching and per-ability cooldown tracking
---@field lastAbilitySwitchTime number Time of last ability switch
---@field abilitySwitchCooldown number Cooldown between ability switches
---@field pendingAttackClear boolean Flag to clear attack input after one frame
---@field abilityCooldowns table<string, number> Per-ability cooldown tracking: abilityId -> lastUsedTime
local AbilitySystem = System:extend("AbilitySystem", {"Ability"})

-- Map slots to ability IDs (1-indexed)
-- Slot 1 (Q) = "lightningbolt"
-- Slot 2 (E) = "flameshock"
-- Slots 3-4 (R-F) are empty for now
AbilitySystem.SLOT_ABILITY_MAP = {
    [1] = "lightningbolt",
    [2] = "flameshock",
    [3] = nil,
    [4] = nil
}

-- Store the original new function
local originalNew = AbilitySystem.new

---Create a new AbilitySystem instance
---@return AbilitySystem
function AbilitySystem.new()
    local self = originalNew()
    self.lastAbilitySwitchTime = 0
    self.abilitySwitchCooldown = 0.2 -- Prevent rapid switching
    self.pendingAttackClear = false -- Flag to clear attack input after one frame
    -- Per-ability cooldown tracking: abilityId -> lastUsedTime
    self.abilityCooldowns = {} -- {[abilityId] = lastUsedTime}
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

    -- Check if player is already casting - if so, ignore the press
    local attack = entity:getComponent("Attack")
    if attack and attack.isCasting then
        -- Player is casting, ignore this ability press
        GameState.input.actionBarSlot = nil
        return true
    end

    -- Use slot mapping
    local slotToAbility = AbilitySystem.SLOT_ABILITY_MAP

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

---Mark an ability as used (starts its cooldown)
---@param abilityId string The ability ID that was used
---@param currentTime number Current game time
function AbilitySystem:markAbilityUsed(abilityId, currentTime)
    if not abilityId then
        return
    end

    -- Ensure abilityCooldowns table exists
    if not self.abilityCooldowns then
        self.abilityCooldowns = {}
    end

    self.abilityCooldowns[abilityId] = currentTime
end

---Check if an ability is ready (cooldown has passed)
---@param abilityId string The ability ID to check
---@param abilityData table|nil The ability data (optional, will be fetched if not provided)
---@param currentTime number Current game time
---@return boolean True if ability is ready
function AbilitySystem:isAbilityReady(abilityId, abilityData, currentTime)
    if not abilityId then
        return true
    end

    -- Get ability data if not provided
    if not abilityData then
        local abilities = require("src.definitions.abilities")
        abilityData = abilities.getAbility(abilityId)
    end

    if not abilityData or not abilityData.cooldown or abilityData.cooldown <= 0 then
        return true -- No cooldown, always ready
    end

    local lastUsedTime = self.abilityCooldowns[abilityId]
    if not lastUsedTime then
        return true -- Never used, ready
    end

    local timeSinceLastUse = currentTime - lastUsedTime
    return timeSinceLastUse >= abilityData.cooldown
end

---Get remaining cooldown time for an ability
---@param abilityId string The ability ID
---@param abilityData table|nil The ability data (optional, will be fetched if not provided)
---@param currentTime number Current game time
---@return number Remaining cooldown time in seconds (0 if ready)
function AbilitySystem:getRemainingCooldown(abilityId, abilityData, currentTime)
    if not abilityId then
        return 0
    end

    -- Get ability data if not provided
    if not abilityData then
        local abilities = require("src.definitions.abilities")
        abilityData = abilities.getAbility(abilityId)
    end

    if not abilityData or not abilityData.cooldown or abilityData.cooldown <= 0 then
        return 0 -- No cooldown
    end

    local lastUsedTime = self.abilityCooldowns[abilityId]
    if not lastUsedTime then
        return 0 -- Never used, ready
    end

    local timeSinceLastUse = currentTime - lastUsedTime
    if timeSinceLastUse >= abilityData.cooldown then
        return 0 -- Cooldown complete
    end

    return abilityData.cooldown - timeSinceLastUse
end

---Get cooldown progress for an ability (0 = ready, 1 = full cooldown)
---@param abilityId string The ability ID
---@param abilityData table|nil The ability data (optional, will be fetched if not provided)
---@param currentTime number Current game time
---@return number Cooldown progress (0-1)
function AbilitySystem:getCooldownProgress(abilityId, abilityData, currentTime)
    if not abilityId then
        return 0
    end

    -- Get ability data if not provided
    if not abilityData then
        local abilities = require("src.definitions.abilities")
        abilityData = abilities.getAbility(abilityId)
    end

    if not abilityData or not abilityData.cooldown or abilityData.cooldown <= 0 then
        return 0 -- No cooldown, always ready
    end

    local remaining = self:getRemainingCooldown(abilityId, abilityData, currentTime)
    if remaining <= 0 then
        return 0
    end

    return remaining / abilityData.cooldown
end

---Get the ability system singleton (for external access)
---@param world World The ECS world
---@return AbilitySystem|nil The ability system instance
function AbilitySystem.getInstance(world)
    if not world then
        return nil
    end

    for _, system in ipairs(world.systems) do
        -- Check if this system is an AbilitySystem by checking for its unique methods
        if system.markAbilityUsed and system.isAbilityReady and system.getCooldownProgress then
            return system
        end
    end

    return nil
end

return AbilitySystem

