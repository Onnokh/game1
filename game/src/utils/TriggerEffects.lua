---@class TriggerEffects
---Utility module for creating common trigger zone effects
local TriggerEffects = {}

---Create a trigger effect based on a configuration table
---@param config table Configuration for the effect
---@return function onEnter callback
---@return function onExit callback
---
---Config structure:
---```lua
---{
---  type = "modifier",        -- Effect type (currently only "modifier" supported)
---  stat = "speed",           -- Stat to modify (e.g., "speed")
---  mode = "multiply",        -- Mode: "multiply" or "add"
---  value = 0.6,              -- Value to apply (0.6 = 60% speed)
---  source = "crystal_stairs" -- Unique identifier for this modifier
---}
---```
---
---Example usage:
---```lua
---local onEnter, onExit = TriggerEffects.createEffect({
---    type = "modifier",
---    stat = "speed",
---    mode = "multiply",
---    value = 0.6,
---    source = "crystal_stairs",
---})
---```
function TriggerEffects.createEffect(config)
    local effectType = config.type or "modifier"

    if effectType == "modifier" then
        return TriggerEffects._createModifierEffect(config)
    elseif effectType == "damage" then
        return TriggerEffects._createDamageEffect(config)
    elseif effectType == "heal" then
        return TriggerEffects._createHealEffect(config)
    else
        error("Unknown trigger effect type: " .. tostring(effectType))
    end
end

---Internal: Create a modifier effect
---@param config table Configuration for the modifier
---@return function onEnter callback
---@return function onExit callback
function TriggerEffects._createModifierEffect(config)
    local stat = config.stat or "speed"
    local mode = config.mode or "multiply"
    local value = config.value or 1.0
    local source = config.source or "unknown"

    local onEnter = function(entity, triggerZone)
        -- Apply modifier to Movement component
        local movement = entity:getComponent("Movement")
        if movement and movement.addModifier then
            movement:addModifier(source, stat, mode, value)
        end
    end

    local onExit = function(entity, triggerZone)
        -- Remove modifier from Movement component
        local movement = entity:getComponent("Movement")
        if movement and movement.removeModifier then
            movement:removeModifier(source)
        end
    end

    return onEnter, onExit
end

---Internal: Create a damage effect
---@param config table Configuration for the damage effect
---@return function onEnter callback
---@return function onExit callback
function TriggerEffects._createDamageEffect(config)
    local damagePerSecond = config.damagePerSecond or 10
    local damageType = config.damageType or nil

    local onEnter = function(entity, triggerZone)
        -- Mark entity as being in damage zone
        if not triggerZone.data.damageTargets then
            triggerZone.data.damageTargets = {}
        end
        triggerZone.data.damageTargets[entity.id] = {
            entity = entity,
            damagePerSecond = damagePerSecond,
            damageType = damageType
        }
    end

    local onExit = function(entity, triggerZone)
        -- Remove entity from damage zone
        if triggerZone.data.damageTargets then
            triggerZone.data.damageTargets[entity.id] = nil
        end
    end

    return onEnter, onExit
end

---Internal: Create a healing effect
---@param config table Configuration for the healing effect
---@return function onEnter callback
---@return function onExit callback
function TriggerEffects._createHealEffect(config)
    local healPerSecond = config.healPerSecond or 10

    local onEnter = function(entity, triggerZone)
        -- Mark entity as being in healing zone
        if not triggerZone.data.healTargets then
            triggerZone.data.healTargets = {}
        end
        triggerZone.data.healTargets[entity.id] = {
            entity = entity,
            healPerSecond = healPerSecond
        }
    end

    local onExit = function(entity, triggerZone)
        -- Remove entity from healing zone
        if triggerZone.data.healTargets then
            triggerZone.data.healTargets[entity.id] = nil
        end
    end

    return onEnter, onExit
end

return TriggerEffects

