---@class Coin
---@field value number The value of this coin
local Coin = {}
Coin.__index = Coin

---Create a new Coin component
---@param value number|nil The value of the coin, defaults to 1
---@return Component|Coin
function Coin.new(value)
    local Component = require("src.core.Component")
    local self = setmetatable(Component.new("Coin"), Coin)

    self.value = value or 1
    
    return self
end

---Set the coin value
---@param newValue number New coin value
function Coin:setValue(newValue)
    self.value = newValue
end

---Get the coin value
---@return number Coin value
function Coin:getValue()
    return self.value
end

return Coin
