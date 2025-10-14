local gameController = require("src.core.GameController")
local gameState = require("src.core.GameState")
local UIElement = require("src.ui.UIElement")
local Button = require("src.ui.Button")
local fonts = require("src.utils.fonts")

---@class PauseMenu: UIElement

local PauseMenu = setmetatable({}, { __index = UIElement })
PauseMenu.__index = PauseMenu

function PauseMenu.new()
    local self = setmetatable(UIElement.new(), PauseMenu)

    -- Create buttons
    self.buttons = {
        Button.new("Resume", function()
            gameController.togglePause()
        end),
        Button.new("Save and Exit", function()
            local SaveSystem = require("src.utils.SaveSystem")
            SaveSystem.save()
            gameController.resetPauseState()
            gameState.changeScene("menu")
        end)
    }

    self.selectedIndex = 1
    self.buttons[self.selectedIndex].selected = true

    return self
end

function PauseMenu:update(dt, gameState)
    -- Update button hover states
    if self.visible then
        local mouseX, mouseY = love.mouse.getPosition()
        for i, btn in ipairs(self.buttons) do
            btn:updateHover(mouseX, mouseY)
        end
    end
end

function PauseMenu:handleMousePressed(x, y, button)
    if not self.visible or button ~= 1 then return false end

    for i, btn in ipairs(self.buttons) do
        if btn:contains(x, y) then
            btn:setPressed(true)
            return true
        end
    end
    return false
end

function PauseMenu:handleMouseReleased(x, y, button)
    if not self.visible or button ~= 1 then return false end

    for i, btn in ipairs(self.buttons) do
        btn:setPressed(false)
        if btn:handleClick(x, y) then
            return true
        end
    end
    return false
end

-- Keep for backwards compatibility
function PauseMenu:handleMouseClick(x, y, button)
    return self:handleMouseReleased(x, y, button)
end

function PauseMenu:handleKeyPress(key)
    if not self.visible then return false end

    -- Navigate between buttons
    if key == "left" or key == "a" or key == "up" or key == "w" then
        self.buttons[self.selectedIndex].selected = false
        self.selectedIndex = self.selectedIndex - 1
        if self.selectedIndex < 1 then self.selectedIndex = #self.buttons end
        self.buttons[self.selectedIndex].selected = true
        return true
    elseif key == "right" or key == "d" or key == "down" or key == "s" then
        self.buttons[self.selectedIndex].selected = false
        self.selectedIndex = self.selectedIndex + 1
        if self.selectedIndex > #self.buttons then self.selectedIndex = 1 end
        self.buttons[self.selectedIndex].selected = true
        return true
    elseif key == "return" or key == "space" then
        self.buttons[self.selectedIndex]:activate()
        return true
    end
    return false
end

function PauseMenu:draw()
    if not self.visible then return end

    -- Save current graphics state
    love.graphics.push("all")

    local sw, sh = love.graphics.getDimensions()

    -- Backdrop
    love.graphics.setColor(0, 0, 0, 0.6)
    love.graphics.rectangle("fill", 0, 0, sw, sh)

    -- Title
    local prevFont = love.graphics.getFont()
    local titleText = "PAUSED"
    local titleFont = fonts.getUIFont(128) or prevFont
    love.graphics.setFont(titleFont)
    local tw = titleFont:getWidth(titleText)
    local th = titleFont:getHeight()
    local tx = math.floor((sw - tw) / 2)
    local ty = math.floor((sh - th) / 2) - 48

    -- Shadowed title
    love.graphics.setColor(0, 0, 0, 0.9)
    love.graphics.print(titleText, tx + 2, ty + 2)
    love.graphics.setColor(0.85, 0.95, 1.0, 1)
    love.graphics.print(titleText, tx, ty)

    -- Draw buttons
    local buttonFont = fonts.getUIFont(28) or prevFont
    local gap = 16

    -- Calculate maximum button width for consistent sizing
    local maxButtonWidth = 0
    for _, btn in ipairs(self.buttons) do
        btn:updateBounds(0, 0, buttonFont)
        maxButtonWidth = math.max(maxButtonWidth, btn.width)
    end

    -- Calculate total width with uniform button sizes
    local totalWidth = maxButtonWidth * #self.buttons + gap * (#self.buttons - 1)

    local baseX = math.floor((sw - totalWidth) / 2)
    local baseY = ty + th + 36

    local currentX = baseX
    for _, btn in ipairs(self.buttons) do
        btn:updateBounds(currentX, baseY, buttonFont)
        btn.width = maxButtonWidth -- Override to use max width
        btn:draw(buttonFont)
        currentX = currentX + maxButtonWidth + gap
    end

    if prevFont then love.graphics.setFont(prevFont) end
    love.graphics.pop()
end

return PauseMenu
