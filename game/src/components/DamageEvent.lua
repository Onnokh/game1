---@class DamageEvent
---@field amount number Amount of damage to deal
---@field source Entity|nil Entity that caused the damage
---@field damageType string Type of damage ("physical", "magic", "fire", etc.)
---@field knockback number Knockback force to apply
---@field effects table|nil Additional effects to apply
local DamageEvent = {}
DamageEvent.__index = DamageEvent

---Create a new DamageEvent component
---@param amount number|nil Amount of damage to deal
---@param source Entity|nil Entity that caused the damage
---@param damageType string|nil Type of damage
---@param knockback number|nil Knockback force to apply
---@param effects table|nil Additional effects to apply
---@return Component|DamageEvent
function DamageEvent.new(amount, source, damageType, knockback, effects)
    local Component = require("src.core.Component")
    local self = setmetatable(Component.new("DamageEvent"), DamageEvent)

    self.amount = amount or 0
    self.source = source
    self.damageType = damageType or "physical"
    self.knockback = knockback or 0
    self.effects = effects or {}

    return self
end

---Set the damage amount
---@param amount number New damage amount
function DamageEvent:setAmount(amount)
    self.amount = math.max(0, amount)
end

---Set the damage source
---@param source Entity|nil Entity that caused the damage
function DamageEvent:setSource(source)
    self.source = source
end

---Set the damage type
---@param damageType string New damage type
function DamageEvent:setDamageType(damageType)
    self.damageType = damageType or "physical"
end

---Set the knockback force
---@param knockback number New knockback force
function DamageEvent:setKnockback(knockback)
    self.knockback = math.max(0, knockback)
end

---Add an effect to the damage event
---@param effect string Effect name
---@param value any Effect value
function DamageEvent:addEffect(effect, value)
    self.effects[effect] = value
end

---Get an effect value
---@param effect string Effect name
---@return any Effect value or nil
function DamageEvent:getEffect(effect)
    return self.effects[effect]
end

---Check if the damage event has a specific effect
---@param effect string Effect name
---@return boolean True if the effect exists
function DamageEvent:hasEffect(effect)
    return self.effects[effect] ~= nil
end

---Clear all effects
function DamageEvent:clearEffects()
    self.effects = {}
end

---Create a copy of this damage event
---@return Component|DamageEvent New damage event with same properties
function DamageEvent:clone()
    local newEvent = DamageEvent.new(self.amount, self.source, self.damageType, self.knockback, {})
    -- Copy effects
    for effect, value in pairs(self.effects) do
        newEvent.effects[effect] = value
    end
    return newEvent
end

return DamageEvent
