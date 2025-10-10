---@class GameOver: UIElement
local UIElement = require("src.ui.UIElement")
local Button = require("src.ui.Button")
local fonts = require("src.utils.fonts")

local GameOver = setmetatable({}, { __index = UIElement })
GameOver.__index = GameOver

function GameOver.new()
    local self = setmetatable(UIElement.new(), GameOver)

    -- Create buttons
    self.buttons = {
        Button.new("Restart", function()
            local controller = require("src.core.GameController")
            if controller and controller.restartGame then controller.restartGame() end
        end),
        Button.new("Back to Menu", function()
            local controller = require("src.core.GameController")
            if controller and controller.backToMenu then controller.backToMenu() end
        end)
    }

    self.selectedIndex = 1
    self.buttons[self.selectedIndex].selected = true

    return self
end

function GameOver:update(dt, gameState)
    -- Update button hover states
    if self.visible then
        local mouseX, mouseY = love.mouse.getPosition()
        for i, btn in ipairs(self.buttons) do
            btn:updateHover(mouseX, mouseY)
        end
    end
end

function GameOver:draw()
    if not self.visible then return end

    local sw, sh = love.graphics.getDimensions()
    local prevFont = love.graphics.getFont()

    love.graphics.push("all")

    local text = "GAME OVER"
    local font = fonts.getUIFont(128)
    if font then love.graphics.setFont(font) end

    local tw = (font and font:getWidth(text)) or 0
    local th = (font and font:getHeight()) or 0
    local x = math.floor((sw - tw) / 2)
    local y = math.floor((sh - th) / 2)

    -- Backdrop
    love.graphics.setColor(0, 0, 0, 0.4)
    love.graphics.rectangle("fill", 0, 0, sw, sh)

    -- Shadowed title
    love.graphics.setColor(0, 0, 0, 0.9)
    love.graphics.print(text, x + 2, y + 2)
    love.graphics.setColor(1, 0.25, 0.25, 1)
    love.graphics.print(text, x, y)

    -- Draw buttons
    local buttonFont = fonts.getUIFont(28)
    local gap = 16

    -- Update button positions
    local totalWidth = 0
    for _, btn in ipairs(self.buttons) do
        btn:updateBounds(0, 0, buttonFont)
        totalWidth = totalWidth + btn.width
    end
    totalWidth = totalWidth + gap * (#self.buttons - 1)

    local baseX = math.floor((sw - totalWidth) / 2)
    local baseY = y + th + 36

    local currentX = baseX
    for _, btn in ipairs(self.buttons) do
        btn:updateBounds(currentX, baseY, buttonFont)
        btn:draw(buttonFont)
        currentX = currentX + btn.width + gap
    end

    if prevFont then love.graphics.setFont(prevFont) end
    love.graphics.pop()
end

function GameOver:handleMousePressed(x, y, button)
    if not self.visible or button ~= 1 then return false end

    for i, btn in ipairs(self.buttons) do
        if btn:contains(x, y) then
            btn:setPressed(true)
            return true
        end
    end
    return false
end

function GameOver:handleMouseReleased(x, y, button)
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
function GameOver:handleMouseClick(x, y, button)
    return self:handleMouseReleased(x, y, button)
end

function GameOver:handleKeyPress(key)
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

return GameOver


