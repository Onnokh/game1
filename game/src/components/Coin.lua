---@class Coin
---@field value number The value of this coin
---@field attractorRadius number The radius at which this coin starts being attracted to the player
---@field spawnTime number The time when this coin was created
local Coin = {}
Coin.__index = Coin

---Create a new Coin component
---@param value number|nil The value of the coin, defaults to 1
---@param attractorRadius number|nil The attraction radius for this coin, defaults to 64
---@return Component|Coin
function Coin.new(value, attractorRadius)
    local Component = require("src.core.Component")
    local self = setmetatable(Component.new("Coin"), Coin)

    self.value = value or 1
    self.attractorRadius = attractorRadius or 64 -- Default attraction radius of 64 pixels
    self.spawnTime = love.timer.getTime() -- Record when this coin was created

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

---Set the coin attractor radius
---@param newRadius number New attractor radius
function Coin:setAttractorRadius(newRadius)
    self.attractorRadius = newRadius
end

---Get the coin attractor radius
---@return number Coin attractor radius
function Coin:getAttractorRadius()
    return self.attractorRadius
end

return Coin
