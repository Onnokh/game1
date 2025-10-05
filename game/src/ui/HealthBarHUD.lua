---@class HealthBarHUD
local HealthBarHUD = {}

---Draw the player's health bar in screen space (bottom-left)
---@param world World
function HealthBarHUD.draw(world)
    if not world or not world.entities then
        return
    end

    -- Find player
    local player = nil
    for _, entity in ipairs(world.entities) do
        if entity.isPlayer then
            player = entity
            break
        end
    end
    if not player then
        return
    end

    local health = player:getComponent("Health")
    if not health or health.isDead then
        return
    end

    love.graphics.push()
    love.graphics.origin()

    local sw, sh = love.graphics.getDimensions()
    local marginX, marginY = 32, 32
    local barWidth, barHeight = 480, 32

    local x = marginX
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
    love.graphics.setColor(r, g, b, a)

    love.graphics.pop()
end

return HealthBarHUD


