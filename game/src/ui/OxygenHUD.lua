---@class OxygenHUD
local OxygenHUD = {}
local fonts = require("src.utils.fonts")

---Draw the player's oxygen bar in screen space (bottom-right)
---@param world World
function OxygenHUD.draw(world)
    if not world or not world.entities then
        return
    end

    local player = world.getPlayer and world:getPlayer() or nil
    if not player then
        return
    end

    local oxygen = player:getComponent("Oxygen")
    if not oxygen then
        return
    end

    love.graphics.push()
    love.graphics.origin()

    local sw, sh = love.graphics.getDimensions()
    local marginX, marginY = 32, 64
    local barWidth, barHeight = 320, 32
    local healthBarHeight = 64
    local gapBetweenBars = 16 -- Gap between oxygen and health bars

    local x = sw/2 - barWidth/2 -- Center horizontally like health bar
    local y = sh - marginY - healthBarHeight - gapBetweenBars - barHeight -- Position above health bar

    local pct = math.max(0, math.min(1, oxygen:getOxygenPercentage()))

    local r, g, b, a = love.graphics.getColor()
    local prevLineWidth = love.graphics.getLineWidth()

    -- Background
    love.graphics.setColor(0.15, 0.15, 0.15, 0.9)
    love.graphics.rectangle("fill", x, y, barWidth, barHeight, 6, 6)

    -- Oxygen fill with color based on oxygen level
    if pct > 0 then
        local oxygenColor = {r = 0.2, g = 0.6, b = 0.8} -- Blue for oxygen
        if pct < 0.3 then
            oxygenColor = {r = 0.8, g = 0.2, b = 0.2} -- Red when low
        elseif pct < 0.6 then
            oxygenColor = {r = 0.8, g = 0.6, b = 0.2} -- Orange when medium
        end

        love.graphics.setColor(oxygenColor.r, oxygenColor.g, oxygenColor.b, 1.0)
        love.graphics.rectangle("fill", x, y, barWidth * pct, barHeight, 6, 6)
    end

    -- Border
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", x, y, barWidth, barHeight, 6, 6)

    love.graphics.setLineWidth(prevLineWidth)

    -- Draw current oxygen value, centered in the bar
    do
        local oxy = math.max(0, math.floor((oxygen.current or 0) + 0.5))
        local text = tostring(oxy)
        local font = fonts.getUIFont(28)
        local prevFont = love.graphics.getFont()
        if font then love.graphics.setFont(font) end

        local textWidth = (font and font:getWidth(text)) or 0
        local textHeight = (font and font:getHeight()) or 28
        local tx = x + (barWidth * 0.5) - (textWidth * 0.5)
        local ty = y + (barHeight * 0.5) - (textHeight * 0.5)

        -- Subtle shadow for readability
        love.graphics.setColor(0, 0, 0, 0.8)
        love.graphics.print(text, tx + 1, ty + 1)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print(text, tx, ty)

        if prevFont then love.graphics.setFont(prevFont) end
    end

    -- Restore color and stack
    love.graphics.setColor(r, g, b, a)
    love.graphics.pop()
end

return OxygenHUD
