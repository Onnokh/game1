---@class Mana
---@field current number Current mana value
---@field max number Maximum mana value
---@field isDepleted boolean Whether the entity has no mana
local Mana = {}
Mana.__index = Mana

---Create a new Mana component
---@param maxMana number Maximum mana value
---@param currentMana number|nil Current mana value, defaults to maxMana
---@return Component|Mana
function Mana.new(maxMana, currentMana)
    local Component = require("src.core.Component")
    local self = setmetatable(Component.new("Mana"), Mana)

    self.max = maxMana or 100
    self.current = currentMana or self.max
    self.isDepleted = false

    return self
end

---Consume mana and reduce current mana
---@param amount number Amount of mana to consume
---@return number Actual amount consumed
function Mana:consumeMana(amount)
    if self.isDepleted then
        return 0
    end

    local oldMana = self.current
    self.current = math.max(0, self.current - amount)

    if self.current <= 0 then
        self.isDepleted = true
        self.current = 0
    end

    return oldMana - self.current
end

---Restore mana and increase current mana
---@param amount number Amount of mana to restore
---@return number Actual amount restored
function Mana:restoreMana(amount)
    if self.isDepleted and amount > 0 then
        self.isDepleted = false
    end

    local oldMana = self.current
    self.current = math.min(self.max, self.current + amount)
    return self.current - oldMana
end

---Set mana to a specific value
---@param value number Mana value to set
function Mana:setMana(value)
    self.current = math.max(0, math.min(self.max, value))
    self.isDepleted = self.current <= 0
end

---Set maximum mana
---@param value number New maximum mana value
function Mana:setMaxMana(value)
    self.max = math.max(1, value)
    if self.current > self.max then
        self.current = self.max
    end
end

---Get mana percentage (0-1)
---@return number Mana percentage
function Mana:getManaPercentage()
    if self.max <= 0 then
        return 0
    end
    return self.current / self.max
end

---Check if the entity is at full mana
---@return boolean True if at full mana
function Mana:isFullMana()
    return self.current >= self.max
end

---Check if the entity has enough mana for a cost
---@param cost number Mana cost to check
---@return boolean True if has enough mana
function Mana:hasEnoughMana(cost)
    return self.current >= cost
end

---Check if the entity is depleted
---@return boolean True if depleted
function Mana:isDepletedMana()
    return self.isDepleted
end

---Get mana status as a string
---@return string Mana status string
function Mana:getStatus()
    if self.isDepleted then
        return "Depleted"
    elseif self:isFullMana() then
        return "Full Mana"
    else
        return string.format("%.0f%% Mana", self:getManaPercentage() * 100)
    end
end

---Serialize the Mana component for saving
---@return table Serialized mana data
function Mana:serialize()
    return {
        current = self.current,
        max = self.max,
        isDepleted = self.isDepleted
    }
end

---Deserialize Mana component from saved data
---@param data table Serialized mana data
---@return Mana Recreated Mana component
function Mana.deserialize(data)
    local mana = Mana.new(data.max, data.current)
    mana.isDepleted = data.isDepleted
    return mana
end

return Mana

