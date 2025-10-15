---@class DashChargesHUD
local DashChargesHUD = {}
local fonts = require("src.utils.fonts")
local EventBus = require("src.utils.EventBus")
local Animation = require("src.core.Animation")

-- Animation manager for pulse effects
local animationManager = require("src.core.Animation").AnimationManager.new()
local lastUpdateTime = 0

-- Subscribe to dash charge events
EventBus.subscribe("dashChargeAvailable", function(payload)
    local chargeIndex = payload.chargeIndex
    local animationId = "dashChargePulse_" .. chargeIndex

    -- Create a pulse animation using the built-in pulse functionality
    local pulseAnimation = animationManager:create(animationId, 1.0, 1.3, .100, "easeInOut", function()
        -- Animation complete - remove it
        animationManager:remove(animationId)
    end)

    -- Set it to pulse mode (grow then shrink back)
    pulseAnimation:setPulse(true)
end)

---Draw the player's dash charges in screen space (below health bar, centered)
---@param world World
function DashChargesHUD.draw(world)
    if not world or not world.entities then
        return
    end

    local player = world.getPlayer and world:getPlayer() or nil
    if not player then
        return
    end

    local dashCharges = player:getComponent("DashCharges")
    if not dashCharges then
        return
    end

    love.graphics.push()
    love.graphics.origin()

    local sw, sh = love.graphics.getDimensions()
    local marginX, marginY = 32, 16
    local healthBarWidth, healthBarHeight = 640, 64
    local gapBelowHealthBar = 16 -- Gap between health bar and dash charges

    -- Dash charge bar dimensions (horizontal layout)
    local barWidth = 48
    local barHeight = 12
    local barGap = 4
    local totalWidth = (barWidth * 3) + (barGap * 2)

    -- Position below health bar, centered horizontally
    local x = sw/2 - totalWidth/2 -- Center horizontally like health bar
    local y = sh - marginY - gapBelowHealthBar - barHeight -- Position above the bottom margin

    local r, g, b, a = love.graphics.getColor()
    local prevLineWidth = love.graphics.getLineWidth()

    -- Get charge data
    local maxCharges = dashCharges:getMaxCharges()
    local availableCharges = dashCharges:getAvailableCharges()
    local chargeProgress = dashCharges:getChargeProgress()

    -- Update animations with delta time
    local currentTime = love.timer.getTime()
    local dt = lastUpdateTime == 0 and 1/60 or (currentTime - lastUpdateTime)
    lastUpdateTime = currentTime
    animationManager:update(dt)

    -- Draw each charge bar (horizontal layout)
    for i = 1, maxCharges do
        local barX = x + (i - 1) * (barWidth + barGap)

        -- Check for pulse animation on this charge
        local animationId = "dashChargePulse_" .. i
        local pulseScale = animationManager:getValue(animationId, 1.0)

        -- Calculate scaled dimensions for pulse effect
        local scaledWidth = barWidth * pulseScale
        local scaledHeight = barHeight * pulseScale
        local scaledX = barX - (scaledWidth - barWidth) / 2
        local scaledY = y - (scaledHeight - barHeight) / 2

        -- Background
        love.graphics.setColor(0.15, 0.15, 0.15, 0.9)
        love.graphics.rectangle("fill", scaledX, scaledY, scaledWidth, scaledHeight, 2, 2)

        -- Fill logic (horizontal fill from left to right)
        if i <= availableCharges then
            -- Fully filled bar
            love.graphics.setColor(1.0, 1.0, 1.0, 1.0) -- White for fully charged
            love.graphics.rectangle("fill", scaledX, scaledY, scaledWidth, scaledHeight, 2, 2)
        elseif i == availableCharges + 1 and availableCharges < maxCharges then
            -- Currently regenerating bar
            local fillWidth = scaledWidth * chargeProgress
            love.graphics.setColor(0.5, 0.5, 0.5, 1.0) -- Light gray for partially charged
            love.graphics.rectangle("fill", scaledX, scaledY, fillWidth, scaledHeight, 2, 2)
        end

        -- Border
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.setLineWidth(1)
        love.graphics.rectangle("line", scaledX, scaledY, scaledWidth, scaledHeight, 2, 2)
    end

    love.graphics.setLineWidth(prevLineWidth)

    -- Restore color and stack
    love.graphics.setColor(r, g, b, a)
    love.graphics.pop()
end

return DashChargesHUD
