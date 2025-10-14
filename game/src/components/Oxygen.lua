---@class Oxygen
---@field current number Current oxygen value
---@field max number Maximum oxygen value
---@field isDepleted boolean Whether oxygen is depleted
local Oxygen = {}
Oxygen.__index = Oxygen

---Create a new Oxygen component
---@param maxOxygen number Maximum oxygen value
---@param currentOxygen number|nil Current oxygen value, defaults to maxOxygen
---@return Component|Oxygen
function Oxygen.new(maxOxygen, currentOxygen)
    local Component = require("src.core.Component")
    local self = setmetatable(Component.new("Oxygen"), Oxygen)

    self.max = maxOxygen or 100
    self.current = currentOxygen or self.max
    self.isDepleted = false

    return self
end

---Reduce oxygen and check for depletion
---@param amount number Amount of oxygen to reduce
---@return boolean Whether oxygen is still available after reduction
function Oxygen:reduce(amount)
    if self.isDepleted then
        return false
    end

    self.current = math.max(0, self.current - amount)

    if self.current <= 0 then
        self.isDepleted = true
        return false
    end

    return true
end

---Restore oxygen
---@param amount number Amount of oxygen to restore
---@return number Actual amount restored
function Oxygen:restore(amount)
    if self.isDepleted then
        self.isDepleted = false
    end

    local oldOxygen = self.current
    self.current = math.min(self.max, self.current + amount)
    return self.current - oldOxygen
end

---Set oxygen to a specific value
---@param value number Oxygen value to set
function Oxygen:setOxygen(value)
    self.current = math.max(0, math.min(self.max, value))
    self.isDepleted = self.current <= 0
end

---Set maximum oxygen
---@param value number New maximum oxygen value
function Oxygen:setMaxOxygen(value)
    self.max = math.max(1, value)
    if self.current > self.max then
        self.current = self.max
    end
end

---Get oxygen percentage (0-1)
---@return number Oxygen percentage
function Oxygen:getOxygenPercentage()
    return self.current / self.max
end

---Check if the entity is at full oxygen
---@return boolean True if at full oxygen
function Oxygen:isFullOxygen()
    return self.current >= self.max
end

---Check if oxygen is available (not depleted)
---@return boolean True if oxygen is available
function Oxygen:isAvailable()
    return not self.isDepleted
end

---Refill oxygen to maximum
function Oxygen:refill()
    self.current = self.max
    self.isDepleted = false
end

---Get oxygen status as a string
---@return string Oxygen status string
function Oxygen:getStatus()
    if self.isDepleted then
        return "No Oxygen"
    elseif self:isFullOxygen() then
        return "Full Oxygen"
    else
        return string.format("%.0f%% Oxygen", self:getOxygenPercentage() * 100)
    end
end

---Serialize the Oxygen component for saving
---@return table Serialized oxygen data
function Oxygen:serialize()
    return {
        current = self.current,
        max = self.max,
        isDepleted = self.isDepleted
    }
end

---Deserialize Oxygen component from saved data
---@param data table Serialized oxygen data
---@return Oxygen Recreated Oxygen component
function Oxygen.deserialize(data)
    local oxygen = Oxygen.new(data.max, data.current)
    oxygen.isDepleted = data.isDepleted
    return oxygen
end

return Oxygen
