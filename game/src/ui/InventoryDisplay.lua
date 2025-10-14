local UIElement = require("src.ui.UIElement")
local fonts = require("src.utils.fonts")

---@class InventoryDisplay : UIElement
---@field x number X position (top-right corner)
---@field y number Y position (top-right corner)
---@field items table Array of inventory items {id, name, amount}
---@field font love.Font Font for rendering text
---@field maxDisplayItems number Maximum items to display (default 10)
local InventoryDisplay = {}
InventoryDisplay.__index = InventoryDisplay

---Create a new InventoryDisplay UI element
---@param x number X position
---@param y number Y position
---@return InventoryDisplay
function InventoryDisplay.new(x, y)
    local self = UIElement.new()
    setmetatable(self, InventoryDisplay)

    self.x = x
    self.y = y
    self.items = {}
    self.font = fonts.getUIFont(24) -- Smaller font for list
    self.maxDisplayItems = 10 -- Show up to 10 items

    return self
end

---Update the inventory display with current items
---@param items table Array of {id, name, amount}
function InventoryDisplay:updateItems(items)
    self.items = items or {}
end

---Draw the inventory display
function InventoryDisplay:draw()
    if not self.visible then return end
    if #self.items == 0 then return end -- Don't draw if inventory is empty

    -- Save current graphics state
    local r, g, b, a = love.graphics.getColor()
    local prevFont = love.graphics.getFont()

    -- Reset coordinate system for screen-space rendering
    love.graphics.push()
    love.graphics.origin()

    -- Set font
    if self.font then
        love.graphics.setFont(self.font)
    end

    local lineHeight = self.font and self.font:getHeight() or 24
    local padding = 8
    local itemSpacing = lineHeight + 4

    -- Calculate background dimensions
    local maxWidth = 0
    local displayItems = {}
    for i = 1, math.min(#self.items, self.maxDisplayItems) do
        displayItems[i] = self.items[i]
        local text = string.format("%s x%d", self.items[i].name, self.items[i].amount)
        local textWidth = self.font and self.font:getWidth(text) or 100
        maxWidth = math.max(maxWidth, textWidth)
    end

    -- Account for title width as well
    local titleText = "Inventory"
    local titleWidth = self.font and self.font:getWidth(titleText) or 80
    maxWidth = math.max(maxWidth, titleWidth)

    local bgWidth = maxWidth + padding * 2
    -- Background height: padding + title + separator spacing + items + padding
    local bgHeight = padding + lineHeight + 4 + (#displayItems * itemSpacing) + padding

    -- Draw dark background
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle("fill", self.x - bgWidth, self.y, bgWidth, bgHeight)

    -- Draw border
    love.graphics.setColor(1, 1, 1, 0.5)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", self.x - bgWidth, self.y, bgWidth, bgHeight)
    love.graphics.setLineWidth(1)

    -- Draw title
    love.graphics.setColor(1, 1, 0.5, 1) -- Light yellow for title
    local titleText = "Inventory"
    local titleWidth = self.font and self.font:getWidth(titleText) or 80
    love.graphics.print(titleText, self.x - bgWidth + (bgWidth - titleWidth) / 2, self.y + padding)

    -- Draw separator line
    love.graphics.setColor(1, 1, 1, 0.3)
    love.graphics.setLineWidth(1)
    love.graphics.line(
        self.x - bgWidth + padding,
        self.y + padding + lineHeight + 2,
        self.x - padding,
        self.y + padding + lineHeight + 2
    )

    -- Draw items
    love.graphics.setColor(1, 1, 1, 1) -- White text for items
    for i, item in ipairs(displayItems) do
        local text = string.format("%s x%d", item.name, item.amount)
        local itemY = self.y + padding + (i * itemSpacing) + 4

        -- Draw with shadow for readability
        love.graphics.setColor(0, 0, 0, 0.8)
        love.graphics.print(text, self.x - bgWidth + padding + 1, itemY + 1)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print(text, self.x - bgWidth + padding, itemY)
    end

    -- If there are more items, show indicator
    if #self.items > self.maxDisplayItems then
        local moreText = string.format("... +%d more", #self.items - self.maxDisplayItems)
        local moreY = self.y + bgHeight - padding - lineHeight
        love.graphics.setColor(0.7, 0.7, 0.7, 1)
        love.graphics.print(moreText, self.x - bgWidth + padding, moreY)
    end

    -- Restore graphics state
    if prevFont then love.graphics.setFont(prevFont) end
    love.graphics.setColor(r, g, b, a)
    love.graphics.pop()
end

return InventoryDisplay

