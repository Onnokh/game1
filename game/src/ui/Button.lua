local fonts = require("src.utils.fonts")

---@class Button
---@field text string The button text
---@field x number The button x position
---@field y number The button y position
---@field width number The button width
---@field height number The button height
---@field selected boolean Whether the button is selected (keyboard navigation)
---@field hovered boolean Whether the button is hovered (mouse)
---@field pressed boolean Whether the button is currently being pressed
---@field onClick function Callback when button is clicked/activated
---@field paddingX number Horizontal padding
---@field paddingY number Vertical padding
local Button = {}
Button.__index = Button

---Create a new button
---@param text string The button text
---@param onClick function Callback when button is clicked/activated
---@return Button
function Button.new(text, onClick)
    local self = setmetatable({}, Button)
    self.text = text
    self.x = 0
    self.y = 0
    self.width = 0
    self.height = 0
    self.selected = false
    self.hovered = false
    self.pressed = false
    self.onClick = onClick
    self.paddingX = 18
    self.paddingY = 10
    return self
end

---Update button bounds based on font and position
---@param x number X position
---@param y number Y position
---@param font love.Font The font to use for text measurement
function Button:updateBounds(x, y, font)
    self.x = x
    self.y = y

    local textWidth = font:getWidth(self.text)
    local textHeight = font:getHeight()

    self.width = textWidth + self.paddingX * 2
    self.height = textHeight + self.paddingY * 2
end

---Check if a point is inside the button
---@param px number Point x
---@param py number Point y
---@return boolean
function Button:contains(px, py)
    return px >= self.x and py >= self.y and
           px <= self.x + self.width and py <= self.y + self.height
end

---Update button hover state based on mouse position
---@param mouseX number Mouse x position
---@param mouseY number Mouse y position
function Button:updateHover(mouseX, mouseY)
    self.hovered = self:contains(mouseX, mouseY)

    -- Update pressed state: only pressed if mouse is down AND hovering
    if not self.hovered then
        self.pressed = false
    end
end

---Set button pressed state
---@param isPressed boolean Whether the button is pressed
function Button:setPressed(isPressed)
    if self.hovered then
        self.pressed = isPressed
    else
        self.pressed = false
    end
end

---Handle click event
---@param x number Click x position
---@param y number Click y position
---@return boolean Whether the click was handled
function Button:handleClick(x, y)
    if self:contains(x, y) then
        if self.onClick then
            self.onClick()
        end
        return true
    end
    return false
end

---Activate the button (keyboard selection)
function Button:activate()
    if self.onClick then
        self.onClick()
    end
end

---Draw the button
---@param font love.Font The font to use for text
function Button:draw(font)
    local offsetX = 0
    local offsetY = 0

    -- Pressed state: slightly offset for depth effect
    if self.pressed then
        offsetX = 1
        offsetY = 1
    end

    -- Shadow (skip if pressed for depth effect)
    if not self.pressed then
        love.graphics.setColor(0, 0, 0, 0.7)
        love.graphics.rectangle("fill", self.x + 2, self.y + 2, self.width, self.height, 6, 6)
    end

    -- Button background - different colors for different states
    if self.pressed then
        -- Pressed: darkest
        love.graphics.setColor(0.15, 0.2, 0.25, 1)
    elseif self.selected or self.hovered then
        -- Hovered or selected: lighter
        love.graphics.setColor(0.35, 0.4, 0.5, 1)
    else
        -- Default: medium
        love.graphics.setColor(0.2, 0.25, 0.3, 1)
    end
    love.graphics.rectangle("fill", self.x + offsetX, self.y + offsetY, self.width, self.height, 6, 6)

    -- Hover border (different from selection)
    if self.hovered and not self.selected and not self.pressed then
        love.graphics.setColor(0.5, 0.6, 0.7, 0.8)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", self.x + offsetX, self.y + offsetY, self.width, self.height, 6, 6)
    end

    -- Selection border (keyboard navigation)
    if self.selected then
        love.graphics.setColor(0.6, 0.8, 1.0, 1)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", self.x + offsetX, self.y + offsetY, self.width, self.height, 6, 6)
    end

    -- Button text
    love.graphics.setFont(font)
    if self.pressed then
        love.graphics.setColor(0.9, 0.9, 0.9, 1)
    else
        love.graphics.setColor(1, 1, 1, 1)
    end
    local textX = math.floor(self.x + self.paddingX + offsetX)
    local textY = math.floor(self.y + self.paddingY + offsetY)
    love.graphics.print(self.text, textX, textY)
end

return Button

