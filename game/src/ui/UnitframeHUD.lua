---@class UnitframeHUD
local UnitframeHUD = {}
local EventBus = require("src.utils.EventBus")
local fonts = require("src.utils.fonts")
local EntityUtils = require("src.utils.entities")
local IffySprites = require("src.utils.sprites")
local HUDLayout = require("src.ui.utils.HUDLayout")

-- Track latest player damage for HUD text
local lastPlayerDamage = { amount = 0, timestamp = -math.huge }

-- Track level up animation state
local levelUpAnimation = {
    active = false,
    startTime = 0, -- Will be set when animation starts
    duration = 0.6, -- Animation duration in seconds
    scale = 1.0,
    pulsePhase = 0
}

-- Cache for portrait image
local portraitImageCache = nil

-- Load portrait image (cached)
local function getPortraitImage()
    if not portraitImageCache then
        local success, img = pcall(love.graphics.newImage, "resources/portrait/shaman.png")
        if success and img then
            img:setFilter("nearest", "nearest")
            portraitImageCache = img
        end
    end
    return portraitImageCache
end

-- Subscribe once to damage events
EventBus.subscribe("entityDamaged", function(payload)
    local target = payload and payload.target or nil
    local amount = payload and payload.amount or 0
    if EntityUtils.isPlayer(target) then
        lastPlayerDamage.amount = amount
        lastPlayerDamage.timestamp = love.timer.getTime()
    end
end)

-- Subscribe to level gained events
EventBus.subscribe("LevelGained", function(payload)
    if payload then
        levelUpAnimation.active = true
        levelUpAnimation.startTime = love.timer.getTime()
        levelUpAnimation.scale = 1.0
        levelUpAnimation.pulsePhase = 0

        -- Play level up sound
        if _G.SoundManager then
            _G.SoundManager.play("levelup", 0.8, 1.0) -- Placeholder sound name
        end
    end
end)

---Draw the player's health bar in screen space (bottom-left)
---@param world World
function UnitframeHUD.draw(world)
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

    local mana = player:getComponent("Mana")
    local playerLevel = player:getComponent("PlayerLevel")

    love.graphics.push()
    love.graphics.origin()

    local sw, sh = love.graphics.getDimensions()

    -- Get action bar position
    local actionBarX, actionBarY = HUDLayout.getActionBarPosition(sw, sh)

    -- Get unitframe positions
    local pos = HUDLayout.getUnitframePositions(sw, sh, actionBarX, actionBarY)
    local portraitX = pos.portraitX
    local portraitY = pos.portraitY
    local barX = pos.barX
    local barY = pos.barY
    local manaBarY = pos.manaBarY

    local pct = math.max(0, math.min(1, health:getHealthPercentage()))

    local r, g, b, a = love.graphics.getColor()
    local prevLineWidth = love.graphics.getLineWidth()

    -- Draw healthbar background (behind portrait)
    love.graphics.setColor(0.15, 0.15, 0.15, 0.9)
    love.graphics.rectangle("fill", barX, barY, HUDLayout.UNITFRAME_BAR_WIDTH, HUDLayout.UNITFRAME_BAR_HEIGHT, 4, 4)

    -- Draw health fill
    if pct > 0 then
        love.graphics.setColor(0.114, 0.541, 0.114, 1.0) -- #1d8a1d green color
        love.graphics.rectangle("fill", barX, barY, HUDLayout.UNITFRAME_BAR_WIDTH * pct, HUDLayout.UNITFRAME_BAR_HEIGHT, 4, 4)
    end

    -- Draw healthbar border
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", barX, barY, HUDLayout.UNITFRAME_BAR_WIDTH, HUDLayout.UNITFRAME_BAR_HEIGHT, 4, 4)

    love.graphics.setLineWidth(prevLineWidth)

    -- Draw manabar background (behind portrait)
    local manaPct = 1.0
    if mana then
        manaPct = math.max(0, math.min(1, mana:getManaPercentage()))
    end
    love.graphics.setColor(0.15, 0.15, 0.15, 0.9)
    love.graphics.rectangle("fill", barX, manaBarY, HUDLayout.UNITFRAME_MANA_BAR_WIDTH, HUDLayout.UNITFRAME_MANA_BAR_HEIGHT, 4, 4)

    -- Draw mana fill (blue)
    if manaPct > 0 then
        love.graphics.setColor(0.2, 0.4, 0.8, 1.0) -- Blue color
        love.graphics.rectangle("fill", barX, manaBarY, HUDLayout.UNITFRAME_MANA_BAR_WIDTH * manaPct, HUDLayout.UNITFRAME_MANA_BAR_HEIGHT, 4, 4)
    end

    -- Draw manabar border
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", barX, manaBarY, HUDLayout.UNITFRAME_MANA_BAR_WIDTH, HUDLayout.UNITFRAME_MANA_BAR_HEIGHT, 4, 4)

    love.graphics.setLineWidth(prevLineWidth)

    -- Draw circular portrait (on top of bars)
    do
        local portraitImg = getPortraitImage()
        local radius = HUDLayout.UNITFRAME_PORTRAIT_SIZE / 2
        local centerX = portraitX + radius
        local centerY = portraitY + radius

        -- Draw portrait background circle
        love.graphics.setColor(0.25, 0.25, 0.3, 1.0) -- Dark blue-gray solid background
        love.graphics.circle("fill", centerX, centerY, radius)

        -- Draw portrait border circle
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.setLineWidth(3)
        love.graphics.circle("line", centerX, centerY, radius)

        -- Draw portrait image with circular mask using stencil
        if portraitImg then
            love.graphics.stencil(function()
                love.graphics.circle("fill", centerX, centerY, radius - 2)
            end, "replace", 1)
            love.graphics.setStencilTest("greater", 0)

            love.graphics.setColor(1, 1, 1, 1)
            local imgW, imgH = portraitImg:getDimensions()
            local scale = HUDLayout.UNITFRAME_PORTRAIT_SIZE / math.max(imgW, imgH)
            local drawW = imgW * scale
            local drawH = imgH * scale
            local drawX = centerX - drawW / 2
            local drawY = centerY - drawH / 2
            love.graphics.draw(portraitImg, drawX, drawY, 0, scale, scale)

            love.graphics.setStencilTest()
        end
    end

    -- Draw level indicator circle at top-left of portrait
    if playerLevel then
        local level = playerLevel:getLevel()
        local levelCircleRadius = 12
        local levelCircleX = portraitX + levelCircleRadius
        local levelCircleY = portraitY + levelCircleRadius

        -- Update level up animation
        if levelUpAnimation.active then
            local currentTime = love.timer.getTime()
            local elapsed = currentTime - levelUpAnimation.startTime
            levelUpAnimation.pulsePhase = elapsed * 10

            if elapsed >= levelUpAnimation.duration then
                levelUpAnimation.active = false
                levelUpAnimation.scale = 1.0
            else
                -- Pulse animation: scale from 1.0 -> 1.5 -> 1.0
                local progress = elapsed / levelUpAnimation.duration
                if progress < 0.3 then
                    -- Scale up quickly
                    levelUpAnimation.scale = 1.0 + (progress / 0.3) * 0.5
                else
                    -- Scale down smoothly
                    local fadeProgress = (progress - 0.3) / 0.7
                    levelUpAnimation.scale = 1.5 - fadeProgress * 0.5
                end
            end
        end

        -- Apply animation scale - use transformation to scale from center
        local currentScale = levelUpAnimation.active and levelUpAnimation.scale or 1.0

        -- Push transformation matrix to scale from center point
        love.graphics.push()
        -- Translate center to origin, scale, then translate back
        love.graphics.translate(levelCircleX, levelCircleY)
        love.graphics.scale(currentScale, currentScale)
        love.graphics.translate(-levelCircleX, -levelCircleY)

        -- Draw level circle background (draw at original position, transforms handle scaling)
        love.graphics.setColor(0, 0, 0, 1.0) -- Fully black
        love.graphics.circle("fill", levelCircleX, levelCircleY, levelCircleRadius)

        -- Draw level circle border with glow effect when animating
        if levelUpAnimation.active then
            -- Pulsing glow effect
            local glowAlpha = 0.5 + 0.5 * math.sin(levelUpAnimation.pulsePhase)
            love.graphics.setColor(1, 1, 0.2, glowAlpha) -- Yellow glow
            love.graphics.setLineWidth(3 / currentScale) -- Adjust line width for scale
            love.graphics.circle("line", levelCircleX, levelCircleY, levelCircleRadius + 2)
        end

        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.setLineWidth(2 / currentScale) -- Adjust line width for scale
        love.graphics.circle("line", levelCircleX, levelCircleY, levelCircleRadius)

        -- Pop transformation matrix
        love.graphics.pop()

        -- Draw level number (not scaled, always centered)
        local levelText = tostring(level)
        local levelFont = fonts.getUIFont(16)
        local prevFont = love.graphics.getFont()
        if levelFont then love.graphics.setFont(levelFont) end

        local levelTextWidth = (levelFont and levelFont:getWidth(levelText)) or 0
        local levelTextHeight = (levelFont and levelFont:getHeight()) or 16
        local levelTextX = levelCircleX - (levelTextWidth * 0.5)
        local levelTextY = levelCircleY - (levelTextHeight * 0.5)

        -- Shadow for readability
        love.graphics.setColor(0, 0, 0, 0.8)
        love.graphics.print(levelText, levelTextX + 1, levelTextY + 1)

        -- Text color changes during animation
        if levelUpAnimation.active then
            local textGlow = 0.5 + 0.5 * math.sin(levelUpAnimation.pulsePhase)
            love.graphics.setColor(1, 1, textGlow, 1) -- Yellow-white glow
        else
            love.graphics.setColor(1, 1, 1, 1)
        end
        love.graphics.print(levelText, levelTextX, levelTextY)

        if prevFont then love.graphics.setFont(prevFont) end
        love.graphics.setLineWidth(prevLineWidth)
    end

    -- Draw current health value, centered in the bar
    do
        local hp = math.max(0, math.floor((health.current or 0) + 0.5))
        local text = tostring(hp)
        local font = fonts.getUIFont(20)
        local prevFont = love.graphics.getFont()
        if font then love.graphics.setFont(font) end

        local textWidth = (font and font:getWidth(text)) or 0
        local textHeight = (font and font:getHeight()) or 20
        local tx = barX + (HUDLayout.UNITFRAME_BAR_WIDTH * 0.5) - (textWidth * 0.5)
        local ty = barY + (HUDLayout.UNITFRAME_BAR_HEIGHT * 0.5) - (textHeight * 0.5)

        -- Subtle shadow for readability
        love.graphics.setColor(0, 0, 0, 0.8)
        love.graphics.print(text, tx + 1, ty + 1)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print(text, tx, ty)

        if prevFont then love.graphics.setFont(prevFont) end
    end

    -- Draw current mana value, centered in the mana bar
    if mana then
        do
            local mp = math.max(0, math.floor((mana.current or 0) + 0.5))
            local text = tostring(mp)
            local font = fonts.getUIFont(20)
            local prevFont = love.graphics.getFont()
            if font then love.graphics.setFont(font) end

            local textWidth = (font and font:getWidth(text)) or 0
            local textHeight = (font and font:getHeight()) or 20
            local tx = barX + (HUDLayout.UNITFRAME_MANA_BAR_WIDTH * 0.5) - (textWidth * 0.5)
            local ty = manaBarY + (HUDLayout.UNITFRAME_MANA_BAR_HEIGHT * 0.5) - (textHeight * 0.5)

            -- Subtle shadow for readability
            love.graphics.setColor(0, 0, 0, 0.8)
            love.graphics.print(text, tx + 1, ty + 1)
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.print(text, tx, ty)

            if prevFont then love.graphics.setFont(prevFont) end
        end
    end

    -- Draw recent damage number right-aligned, 8px from the right edge
    local ttl = 0.9
    local age = love.timer.getTime() - (lastPlayerDamage.timestamp or -math.huge)
    if age >= 0 and age <= ttl and (lastPlayerDamage.amount or 0) > 0 then
        local text = string.format("-%d", math.floor((lastPlayerDamage.amount or 0) + 0.5))
        local font = fonts.getUIFont(18)
        local prevFont = love.graphics.getFont()
        if font then love.graphics.setFont(font) end

        local alpha = 1 - (age / ttl)
        -- Simple grow from 0.8 to 1.0 over time
        local pulse = 1 + 0.2 * math.exp(-age * 3)
        local textWidth = (font and font:getWidth(text)) or 0
        local textHeight = (font and font:getHeight()) or 18
        local tx = barX + HUDLayout.UNITFRAME_BAR_WIDTH - 12 - textWidth
        local ty = barY + (HUDLayout.UNITFRAME_BAR_HEIGHT * 0.5) - (textHeight * 0.5)

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

return UnitframeHUD

