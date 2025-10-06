local gameController = require("src.core.GameController")
local gameState = require("src.core.GameState")
local UIElement = require("src.ui.UIElement")
local fonts = require("src.utils.fonts")

---@class PauseMenu: UIElement

local PauseMenu = setmetatable({}, { __index = UIElement })
PauseMenu.__index = PauseMenu

function PauseMenu.new()
    local self = setmetatable(UIElement.new(), PauseMenu)
    self._buttons = {
        resume = { x = 0, y = 0, w = 0, h = 0 },
        menu = { x = 0, y = 0, w = 0, h = 0 }
    }
    return self
end

function PauseMenu:update(dt, gameState)
    -- no-op for now
end

function PauseMenu:handleMouseClick(x, y, button)
    if not self.visible or button ~= 1 then return false end -- Only handle left clicks
    local function inside(rect)
        return x >= rect.x and y >= rect.y and x <= rect.x + rect.w and y <= rect.y + rect.h
    end
    if inside(self._buttons.resume) then
        gameController.togglePause()
        return true
    end
    if inside(self._buttons.menu) then
        gameController.resetPauseState()
        gameState.changeScene("menu")
        return true
    end
    return false
end

function PauseMenu:draw()
    if not self.visible then return end

    -- Save current graphics state
    love.graphics.push("all")

    local sw, sh = love.graphics.getDimensions()

    -- Backdrop to match GameOver style
    love.graphics.setColor(0, 0, 0, 0.6)
    love.graphics.rectangle("fill", 0, 0, sw, sh)

    -- Title styled similarly to GameOver but with different color
    local prevFont = love.graphics.getFont()
    local titleText = "PAUSED"
    local titleFont = fonts.getUIFont(128) or prevFont
    love.graphics.setFont(titleFont)
    local tw = titleFont:getWidth(titleText)
    local th = titleFont:getHeight()
    local tx = math.floor((sw - tw) / 2)
    local ty = math.floor((sh - th) / 2) - 48

    -- shadowed title (cyan/white instead of red)
    love.graphics.setColor(0, 0, 0, 0.9)
    love.graphics.print(titleText, tx + 2, ty + 2)
    love.graphics.setColor(0.85, 0.95, 1.0, 1)
    love.graphics.print(titleText, tx, ty)

    -- Buttons layout (same metrics as GameOver)
    local buttonFont = fonts.getUIFont(28) or prevFont
    local paddingX, paddingY = 18, 10
    local gap = 16

    local resumeText = "Resume"
    local menuText = "Back to Menu"

    local rtw = (buttonFont and buttonFont:getWidth(resumeText)) or 0
    local rth = (buttonFont and buttonFont:getHeight()) or 0
    local mtw = (buttonFont and buttonFont:getWidth(menuText)) or 0
    local mth = (buttonFont and buttonFont:getHeight()) or 0

    local rw = rtw + paddingX * 2
    local mw = mtw + paddingX * 2
    local bh = math.max(rth, mth) + paddingY * 2

    local totalW = rw + gap + mw
    local baseX = math.floor((sw - totalW) / 2)
    local baseY = ty + th + 36

    -- store bounds for clicks
    self._buttons.resume.x, self._buttons.resume.y, self._buttons.resume.w, self._buttons.resume.h = baseX, baseY, rw, bh
    self._buttons.menu.x, self._buttons.menu.y, self._buttons.menu.w, self._buttons.menu.h = baseX + rw + gap, baseY, mw, bh

    -- draw resume button (cool gray/blue)
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", baseX + 2, baseY + 2, rw, bh, 6, 6)
    love.graphics.setColor(0.2, 0.28, 0.38, 1)
    love.graphics.rectangle("fill", baseX, baseY, rw, bh, 6, 6)
    love.graphics.setFont(buttonFont)
    love.graphics.setColor(1, 1, 1, 1)
    local rtx = math.floor(baseX + (rw - rtw) / 2)
    local rty = math.floor(baseY + (bh - rth) / 2)
    love.graphics.print(resumeText, rtx, rty)

    -- draw menu button
    local mx = baseX + rw + gap
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", mx + 2, baseY + 2, mw, bh, 6, 6)
    love.graphics.setColor(0.25, 0.25, 0.25, 1)
    love.graphics.rectangle("fill", mx, baseY, mw, bh, 6, 6)
    love.graphics.setColor(1, 1, 1, 1)
    local mtx = math.floor(mx + (mw - mtw) / 2)
    local mty = math.floor(baseY + (bh - mth) / 2)
    love.graphics.print(menuText, mtx, mty)

    if prevFont then love.graphics.setFont(prevFont) end
    love.graphics.pop()
end

return PauseMenu
