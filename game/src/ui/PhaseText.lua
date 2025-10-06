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

    local phaseText = tostring(gameState and gameState.phase or "")
    local sw, _ = love.graphics.getDimensions()
    local prevFont = love.graphics.getFont()
    local r, g, b, a = love.graphics.getColor()

    love.graphics.push()
    love.graphics.origin()

    -- Draw DAY as large header on top
    local dayText = string.format("DAY %d", tonumber(gameState and gameState.day or 1) or 1)
    local dayFont = fonts.getUIFont(64)
    if dayFont then love.graphics.setFont(dayFont) end
    local dayWidth = (dayFont and dayFont:getWidth(dayText)) or 0
    local dayX = math.floor((sw - dayWidth) / 2)
    local dayY = 24
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.print(dayText, dayX + 1, dayY + 1)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(dayText, dayX, dayY)

    -- Draw phase as smaller subtitle below day
    if phaseText ~= "" then
        local phaseFont = fonts.getUIFont(22)
        if phaseFont then love.graphics.setFont(phaseFont) end
        local phaseWidth = (phaseFont and phaseFont:getWidth(phaseText)) or 0
        local phaseHeight = (dayFont and dayFont:getHeight()) or 64
        local px = math.floor((sw - phaseWidth) / 2)
        local py = dayY + phaseHeight + 8
        love.graphics.setColor(0, 0, 0, 0.75)
        love.graphics.print(phaseText, px + 1, py + 1)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print(phaseText, px, py)
    end

    if prevFont then love.graphics.setFont(prevFont) end
    love.graphics.setColor(r, g, b, a)
    love.graphics.pop()
end

return PhaseText


