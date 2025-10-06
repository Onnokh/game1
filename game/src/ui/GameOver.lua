---@class GameOver: UIElement
local UIElement = require("src.ui.UIElement")
local fonts = require("src.utils.fonts")

local GameOver = setmetatable({}, { __index = UIElement })
GameOver.__index = GameOver

function GameOver.new()
    local self = setmetatable(UIElement.new(), GameOver)
    self._buttons = {
        restart = { x = 0, y = 0, w = 0, h = 0 },
        menu = { x = 0, y = 0, w = 0, h = 0 }
    }
    return self
end

function GameOver:update(dt, gameState)
    -- no-op
end

function GameOver:draw()
    if not self.visible then return end

    local sw, sh = love.graphics.getDimensions()
    local prevFont = love.graphics.getFont()
    local r, g, b, a = love.graphics.getColor()

    love.graphics.push()
    love.graphics.origin()

    local text = "GAME OVER"
    local font = fonts.getUIFont(128)
    if font then love.graphics.setFont(font) end

    local tw = (font and font:getWidth(text)) or 0
    local th = (font and font:getHeight()) or 0
    local x = math.floor((sw - tw) / 2)
    local y = math.floor((sh - th) / 2)

    -- backdrop
    love.graphics.setColor(0, 0, 0, 0.4)
    love.graphics.rectangle("fill", 0, 0, sw, sh)

    -- shadowed text
    love.graphics.setColor(0, 0, 0, 0.9)
    love.graphics.print(text, x + 2, y + 2)
    love.graphics.setColor(1, 0.25, 0.25, 1)
    love.graphics.print(text, x, y)

    -- buttons layout
    local buttonFont = fonts.getUIFont(28)
    local paddingX, paddingY = 18, 10
    local gap = 16

    local restartText = "Restart"
    local menuText = "Back to Menu"

    local rtw = (buttonFont and buttonFont:getWidth(restartText)) or 0
    local rth = (buttonFont and buttonFont:getHeight()) or 0
    local mtw = (buttonFont and buttonFont:getWidth(menuText)) or 0
    local mth = (buttonFont and buttonFont:getHeight()) or 0

    local rw = rtw + paddingX * 2
    local mw = mtw + paddingX * 2
    local bh = math.max(rth, mth) + paddingY * 2

    local totalW = rw + gap + mw
    local baseX = math.floor((sw - totalW) / 2)
    local baseY = y + th + 36

    -- store bounds
    self._buttons.restart.x, self._buttons.restart.y, self._buttons.restart.w, self._buttons.restart.h = baseX, baseY, rw, bh
    self._buttons.menu.x, self._buttons.menu.y, self._buttons.menu.w, self._buttons.menu.h = baseX + rw + gap, baseY, mw, bh

    -- draw restart button
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", baseX + 2, baseY + 2, rw, bh, 6, 6)
    love.graphics.setColor(0.2, 0.2, 0.2, 1)
    love.graphics.rectangle("fill", baseX, baseY, rw, bh, 6, 6)
    if buttonFont then love.graphics.setFont(buttonFont) end
    love.graphics.setColor(1, 1, 1, 1)
    local rtx = math.floor(baseX + (rw - rtw) / 2)
    local rty = math.floor(baseY + (bh - rth) / 2)
    love.graphics.print(restartText, rtx, rty)

    -- draw menu button
    local mx = baseX + rw + gap
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", mx + 2, baseY + 2, mw, bh, 6, 6)
    love.graphics.setColor(0.2, 0.2, 0.2, 1)
    love.graphics.rectangle("fill", mx, baseY, mw, bh, 6, 6)
    love.graphics.setColor(1, 1, 1, 1)
    local mtx = math.floor(mx + (mw - mtw) / 2)
    local mty = math.floor(baseY + (bh - mth) / 2)
    love.graphics.print(menuText, mtx, mty)

    if prevFont then love.graphics.setFont(prevFont) end
    love.graphics.setColor(r, g, b, a)
    love.graphics.pop()
end

function GameOver:handleMouseClick(x, y, button)
    if not self.visible then return false end
    if button ~= 1 then return false end
    local function inside(rect)
        return x >= rect.x and y >= rect.y and x <= rect.x + rect.w and y <= rect.y + rect.h
    end
    if inside(self._buttons.restart) then
        local controller = require("src.core.GameController")
        if controller and controller.restartGame then controller.restartGame() end
        return true
    end
    if inside(self._buttons.menu) then
        local controller = require("src.core.GameController")
        if controller and controller.backToMenu then controller.backToMenu() end
        return true
    end
    return false
end

return GameOver


