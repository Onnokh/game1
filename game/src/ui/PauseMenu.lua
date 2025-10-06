local gameController = require("src.core.GameController")
local gameState = require("src.core.GameState")
local UIElement = require("src.ui.UIElement")
local fonts = require("src.utils.fonts")

---@class PauseMenu: UIElement

local PauseMenu = setmetatable({}, { __index = UIElement })
PauseMenu.__index = PauseMenu

function PauseMenu.new()
    local self = setmetatable(UIElement.new(), PauseMenu)
    return self
end

function PauseMenu:update(dt, gameState)
    -- no-op for now
end

function PauseMenu:handleMouseClick(x, y, button)
    if not self.visible or button ~= 1 then return false end -- Only handle left clicks

    -- Check if click is within button bounds
    if self.buttonBounds then
        if x >= self.buttonBounds.x and x <= self.buttonBounds.x + self.buttonBounds.width and
           y >= self.buttonBounds.y and y <= self.buttonBounds.y + self.buttonBounds.height then
            -- Button was clicked - go back to menu
            -- Reset pause state before changing scene
            gameController.resetPauseState()
            gameState.changeScene("menu")
            return true
        end
    end

    return false
end

function PauseMenu:draw()
    if not self.visible then return end

    -- Save current graphics state
    love.graphics.push("all")

    -- Get screen dimensions
    local screenWidth, screenHeight = love.graphics.getDimensions()

    -- Calculate overlay dimensions (make it taller for the button)
    local overlayWidth = 220
    local overlayHeight = 160
    local overlayX = (screenWidth - overlayWidth) / 2
    local overlayY = (screenHeight - overlayHeight) / 2

    -- Draw semi-transparent background overlay
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)

    -- Draw pause menu background
    love.graphics.setColor(0.2, 0.2, 0.2, 0.9)
    love.graphics.rectangle("fill", overlayX, overlayY, overlayWidth, overlayHeight)

    -- Draw pause menu border
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", overlayX, overlayY, overlayWidth, overlayHeight)

    -- Draw "PAUSED" text
    local titleFont = fonts.getUIFont(28) or love.graphics.getFont()
    local prevFont = love.graphics.getFont()
    love.graphics.setFont(titleFont)

    local titleText = "PAUSED"
    local titleWidth = titleFont:getWidth(titleText)
    local titleHeight = titleFont:getHeight()
    local titleX = overlayX + (overlayWidth - titleWidth) / 2
    local titleY = overlayY + 25

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(titleText, titleX, titleY)

    -- Draw "Back to Menu" button
    local buttonFont = fonts.getUIFont(16) or love.graphics.getFont()
    love.graphics.setFont(buttonFont)

    local buttonText = "Back to Menu"
    local buttonWidth = buttonFont:getWidth(buttonText)
    local buttonHeight = buttonFont:getHeight()
    local buttonX = overlayX + (overlayWidth - buttonWidth) / 2
    local buttonY = titleY + titleHeight + 30

    -- Button background
    local buttonPadding = 8
    local buttonBgX = buttonX - buttonPadding
    local buttonBgY = buttonY - buttonPadding
    local buttonBgWidth = buttonWidth + (buttonPadding * 2)
    local buttonBgHeight = buttonHeight + (buttonPadding * 2)

    love.graphics.setColor(0.4, 0.4, 0.4, 0.9)
    love.graphics.rectangle("fill", buttonBgX, buttonBgY, buttonBgWidth, buttonBgHeight)

    -- Button border
    love.graphics.setColor(0.8, 0.8, 0.8, 1)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", buttonBgX, buttonBgY, buttonBgWidth, buttonBgHeight)

    -- Button text
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(buttonText, buttonX, buttonY)

    -- Store button bounds for click detection
    self.buttonBounds = {
        x = buttonBgX,
        y = buttonBgY,
        width = buttonBgWidth,
        height = buttonBgHeight
    }

    -- Restore graphics state
    if prevFont then love.graphics.setFont(prevFont) end
    love.graphics.pop()
end

return PauseMenu
