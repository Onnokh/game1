---@class PhaseText: UIElement
local UIElement = require("src.ui.UIElement")
local fonts = require("src.utils.fonts")

local PhaseText = setmetatable({}, { __index = UIElement })
PhaseText.__index = PhaseText

function PhaseText.new()
    local self = setmetatable(UIElement.new(), PhaseText)
    return self
end

function PhaseText:update(dt, gameState)
    -- no-op for now
end

function PhaseText:draw()
    if not self.visible then return end
    local gameState = require("src.core.GameState")

    local text = tostring(gameState and gameState.phase or "")
    if text == "" then return end

    local sw, _ = love.graphics.getDimensions()
    local font = fonts.getUIFont(64)
    local prevFont = love.graphics.getFont()
    local r, g, b, a = love.graphics.getColor()

    love.graphics.push()
    love.graphics.origin()

    if font then love.graphics.setFont(font) end
    local tw = (font and font:getWidth(text)) or 0
    local tx = math.floor((sw - tw) / 2)
    local ty = 32

    -- subtle shadow for readability
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.print(text, tx + 1, ty + 1)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(text, tx, ty)

    if prevFont then love.graphics.setFont(prevFont) end
    love.graphics.setColor(r, g, b, a)
    love.graphics.pop()
end

return PhaseText


