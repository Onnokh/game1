---@class WeaponIndicator
local WeaponIndicator = {}
local fonts = require("src.utils.fonts")
local EntityUtils = require("src.utils.entities")

---Draw the current weapon indicator in screen space
---@param world World
function WeaponIndicator.draw(world)
    if not world or not world.entities then
        return
    end

    local player = world.getPlayer and world:getPlayer() or nil
    if not player then
        return
    end

    local weapon = player:getComponent("Weapon")
    if not weapon then
        return
    end

    local currentWeaponData = weapon:getCurrentWeapon()
    if not currentWeaponData then
        return
    end

    love.graphics.push()
    love.graphics.origin()

    local sw, sh = love.graphics.getDimensions()
    local marginY = 64
    local healthBarWidth = 640

    -- Position to the left of the healthbar
    local indicatorWidth = 180
    local indicatorHeight = 80
    local spacing = 24 -- Space between weapon indicator and healthbar

    local healthBarX = sw/2 - healthBarWidth/2
    local x = healthBarX - indicatorWidth - spacing
    local y = sh - marginY - indicatorHeight

    local r, g, b, a = love.graphics.getColor()
    local prevLineWidth = love.graphics.getLineWidth()


    -- Background with slight transparency
    love.graphics.setColor(0.15, 0.15, 0.15, 0.9)
    love.graphics.rectangle("fill", x, y, indicatorWidth, indicatorHeight, 6, 6)

    -- Border
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", x, y, indicatorWidth, indicatorHeight, 6, 6)

    love.graphics.setLineWidth(prevLineWidth)

    -- Draw weapon type label at the top
    do
        local label = "WEAPON"
        local font = fonts.getUIFont(16)
        local prevFont = love.graphics.getFont()
        if font then love.graphics.setFont(font) end

        local textWidth = (font and font:getWidth(label)) or 0
        local tx = x + (indicatorWidth * 0.5) - (textWidth * 0.5)
        local ty = y + 8

        -- Shadow for readability
        love.graphics.setColor(0, 0, 0, 0.6)
        love.graphics.print(label, tx + 1, ty + 1)
        love.graphics.setColor(0.7, 0.7, 0.7, 1)
        love.graphics.print(label, tx, ty)

        if prevFont then love.graphics.setFont(prevFont) end
    end

    -- Draw weapon type text
    do
        local typeText = currentWeaponData.type == "melee" and "MELEE" or "RANGED"
        local font = fonts.getUIFont(24)
        local prevFont = love.graphics.getFont()
        if font then love.graphics.setFont(font) end

        local textWidth = (font and font:getWidth(typeText)) or 0
        local textHeight = (font and font:getHeight()) or 24
        local tx = x + (indicatorWidth * 0.5) - (textWidth * 0.5)
        local ty = y + 32

        -- Highlight color based on weapon type
        if currentWeaponData.type == "melee" then
            -- Shadow
            love.graphics.setColor(0, 0, 0, 0.8)
            love.graphics.print(typeText, tx + 1, ty + 1)
            -- Main text - Orange for melee
            love.graphics.setColor(1, 0.6, 0.2, 1)
            love.graphics.print(typeText, tx, ty)
        else
            -- Shadow
            love.graphics.setColor(0, 0, 0, 0.8)
            love.graphics.print(typeText, tx + 1, ty + 1)
            -- Main text - Blue for ranged
            love.graphics.setColor(0.4, 0.8, 1, 1)
            love.graphics.print(typeText, tx, ty)
        end

        if prevFont then love.graphics.setFont(prevFont) end
    end

    -- Restore color and stack
    love.graphics.setColor(r, g, b, a)
    love.graphics.pop()
end

return WeaponIndicator

