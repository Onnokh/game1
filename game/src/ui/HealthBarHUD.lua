---@class HealthBarHUD
local HealthBarHUD = {}
local EventBus = require("src.utils.EventBus")
local fonts = require("src.utils.fonts")
local EntityUtils = require("src.utils.entities")

-- Track latest player damage for HUD text
local lastPlayerDamage = { amount = 0, timestamp = -math.huge }

-- Subscribe once to damage events
EventBus.subscribe("entityDamaged", function(payload)
    local target = payload and payload.target or nil
    local amount = payload and payload.amount or 0
    if EntityUtils.isPlayer(target) then
        lastPlayerDamage.amount = amount
        lastPlayerDamage.timestamp = love.timer.getTime()
    end
end)

---Draw the player's health bar in screen space (bottom-left)
---@param world World
function HealthBarHUD.draw(world)
    if not world or not world.entities then
        return
    end

    local player = world.getPlayer and world:getPlayer() or nil
    if not player then
        return
    end

    local health = player:getComponent("Health")
    if not health then
        return
    end

    love.graphics.push()
    love.graphics.origin()

    local sw, sh = love.graphics.getDimensions()
    local marginX, marginY = 32, 64
    local barWidth, barHeight = 640, 64

    local x = sw/2 - barWidth/2
    local y = sh - marginY - barHeight

    local pct = math.max(0, math.min(1, health:getHealthPercentage()))

    local r, g, b, a = love.graphics.getColor()
    local prevLineWidth = love.graphics.getLineWidth()

    -- Background
    love.graphics.setColor(0.15, 0.15, 0.15, 0.9)
    love.graphics.rectangle("fill", x, y, barWidth, barHeight, 6, 6)

    -- Health fill
    if pct > 0 then
        love.graphics.setColor(0.8, 0.2, 0.2, 1.0)
        love.graphics.rectangle("fill", x, y, barWidth * pct, barHeight, 6, 6)
    end

    -- Border
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", x, y, barWidth, barHeight, 6, 6)

    love.graphics.setLineWidth(prevLineWidth)

    -- Draw current health value, centered in the bar
    do
        local hp = math.max(0, math.floor((health.current or 0) + 0.5))
        local text = tostring(hp)
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

    -- Draw recent damage number right-aligned, 8px from the right edge
    local ttl = 0.9
    local age = love.timer.getTime() - (lastPlayerDamage.timestamp or -math.huge)
    if age >= 0 and age <= ttl and (lastPlayerDamage.amount or 0) > 0 then
        local text = string.format("-%d", math.floor((lastPlayerDamage.amount or 0) + 0.5))
        local font = fonts.getUIFont(24)
        local prevFont = love.graphics.getFont()
        if font then love.graphics.setFont(font) end

        local alpha = 1 - (age / ttl)
        -- Simple grow from 0.8 to 1.0 over time
        local pulse = 1 + 0.2 * math.exp(-age * 3)
        local textWidth = (font and font:getWidth(text)) or 0
        local textHeight = (font and font:getHeight()) or 24
        local tx = x + barWidth - 16 - textWidth
        local ty = y + (barHeight * 0.5) - (textHeight * 0.5)

        -- Apply pulsing scale
        love.graphics.push()
        love.graphics.translate(tx + textWidth * 0.5, ty + textHeight * 0.5)
        love.graphics.scale(pulse, pulse)
        love.graphics.translate(-textWidth * 0.5, -textHeight * 0.5)

        -- Shadow and main
        love.graphics.setColor(0, 0, 0, alpha)
        love.graphics.print(text, 1, 1)
        love.graphics.setColor(1, 1, 1, alpha)
        love.graphics.print(text, 0, 0)

        love.graphics.pop()

        if prevFont then love.graphics.setFont(prevFont) end
    end

    -- Restore color and stack
    love.graphics.setColor(r, g, b, a)
    love.graphics.pop()
end

return HealthBarHUD


