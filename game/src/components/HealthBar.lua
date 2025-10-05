---@class HealthBar
---@field width number Width of the health bar in pixels
---@field height number Height of the health bar in pixels
---@field offsetY number Vertical offset from entity position (negative = above)
---@field backgroundColor table Background color (RGBA)
---@field healthColor table Health bar color (RGBA)
---@field borderColor table Border color (RGBA)
---@field borderWidth number Border width in pixels
---@field visible boolean Whether the health bar is visible
local HealthBar = {}
HealthBar.__index = HealthBar

---Create a new HealthBar component
---@param width number|nil Width of the health bar, defaults to 16
---@param height number|nil Height of the health bar, defaults to 2
---@param offsetY number|nil Vertical offset from entity position, defaults to -8 (above)
---@return Component|HealthBar
function HealthBar.new(width, height, offsetY)
    local Component = require("src.core.Component")
    local self = setmetatable(Component.new("HealthBar"), HealthBar)

    self.width = width or 16
    self.height = height or 2
    self.offsetY = offsetY or -8 -- Above the entity
    self.borderWidth = 1
    self.alwaysVisible = false

    -- Default colors
    self.backgroundColor = {r = 0.2, g = 0.2, b = 0.2, a = 0.8} -- Dark gray background
    self.healthColor = {r = 0.8, g = 0.2, b = 0.2, a = 1.0}    -- Red health bar
    self.borderColor = {r = 0.0, g = 0.0, b = 0.0, a = 1.0}    -- Black border

    self.visible = true

    return self
end

---Set the health bar colors
---@param backgroundColor table|nil Background color (RGBA)
---@param healthColor table|nil Health bar color (RGBA)
---@param borderColor table|nil Border color (RGBA)
function HealthBar:setColors(backgroundColor, healthColor, borderColor)
    if backgroundColor then
        self.backgroundColor = backgroundColor
    end
    if healthColor then
        self.healthColor = healthColor
    end
    if borderColor then
        self.borderColor = borderColor
    end
end

---Set the health bar size
---@param width number Width of the health bar
---@param height number Height of the health bar
function HealthBar:setSize(width, height)
    self.width = width
    self.height = height
end

---Set the vertical offset
---@param offsetY number Vertical offset from entity position
function HealthBar:setOffsetY(offsetY)
    self.offsetY = offsetY
end

---Set visibility
---@param visible boolean Whether the health bar is visible
function HealthBar:setVisible(visible)
    self.visible = visible
end

---Force the health bar to always render, even at full health
---@param always boolean
function HealthBar:setAlwaysVisible(always)
    self.alwaysVisible = not not always
end

---Get the health bar position relative to entity position
---@param entityX number Entity X position
---@param entityY number Entity Y position
---@param entityWidth number Entity width (for centering)
---@return number, number Health bar X and Y position
function HealthBar:getPosition(entityX, entityY, entityWidth)
    local x = entityX + (entityWidth - self.width) / 2 -- Center horizontally
    local y = entityY + self.offsetY
    return x, y
end

---Draw the health bar
---@param x number X position
---@param y number Y position
---@param healthPercentage number Health percentage (0-1)
function HealthBar:draw(x, y, healthPercentage)
    if not self.visible then
        return
    end

    -- Clamp health percentage
    healthPercentage = math.max(0, math.min(1, healthPercentage))

    -- Calculate health bar width
    local healthWidth = self.width * healthPercentage

    -- Save current color
    local r, g, b, a = love.graphics.getColor()

    -- Draw background
    love.graphics.setColor(self.backgroundColor.r, self.backgroundColor.g, self.backgroundColor.b, self.backgroundColor.a)
    love.graphics.rectangle("fill", x, y, self.width, self.height)

    -- Draw health bar
    if healthWidth > 0 then
        love.graphics.setColor(self.healthColor.r, self.healthColor.g, self.healthColor.b, self.healthColor.a)
        love.graphics.rectangle("fill", x, y, healthWidth, self.height)
    end

    -- Draw border
    if self.borderWidth > 0 then
        love.graphics.setColor(self.borderColor.r, self.borderColor.g, self.borderColor.b, self.borderColor.a)
        love.graphics.setLineWidth(self.borderWidth)
        love.graphics.rectangle("line", x, y, self.width, self.height)
    end

    -- Restore color
    love.graphics.setColor(r, g, b, a)
end

return HealthBar
