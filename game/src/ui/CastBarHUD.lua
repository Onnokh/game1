---@class CastBarHUD
local CastBarHUD = {}
local fonts = require("src.utils.fonts")
local EntityUtils = require("src.utils.entities")
local abilities = require("src.definitions.abilities")
local HUDLayout = require("src.ui.utils.HUDLayout")

---Draw the cast bar in screen space (above action bar, centered)
---@param world World
function CastBarHUD.draw(world)
    if not world or not world.entities then
        return
    end

    local player = world.getPlayer and world:getPlayer() or nil
    if not player then
        return
    end

    local attack = player:getComponent("Attack")
    if not attack or not attack.isCasting then
        return -- Only show when casting
    end

    love.graphics.push()
    love.graphics.origin()

    local sw, sh = love.graphics.getDimensions()

    -- Get action bar position
    local actionBarX, actionBarY = HUDLayout.getActionBarPosition(sw, sh)

    -- Get cast bar position (128px above action bar)
    local x, y, castBarWidth = HUDLayout.getCastBarPosition(sw, sh, actionBarX, actionBarY)

    local currentTime = love.timer.getTime()
    local progress = attack:getCastProgress(currentTime)

    local r, g, b, a = love.graphics.getColor()
    local prevLineWidth = love.graphics.getLineWidth()

    -- Background
    love.graphics.setColor(0.15, 0.15, 0.15, 0.9)
    love.graphics.rectangle("fill", x, y, castBarWidth, HUDLayout.CAST_BAR_HEIGHT, 6, 6)

    -- Cast fill (blue/cyan color)
    if progress > 0 then
        love.graphics.setColor(0.2, 0.6, 1.0, 1.0) -- Blue/cyan for casting
        love.graphics.rectangle("fill", x, y, castBarWidth * progress, HUDLayout.CAST_BAR_HEIGHT, 6, 6)
    end

    -- Border
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", x, y, castBarWidth, HUDLayout.CAST_BAR_HEIGHT, 6, 6)

    love.graphics.setLineWidth(prevLineWidth)

    -- Draw ability name, centered in the bar
    local abilityId = attack.castAbilityId
    local abilityName = "Casting..."
    if abilityId then
        local abilityData = abilities.getAbility(abilityId)
        if abilityData then
            abilityName = abilityData.name or abilityId
        end
    end

    local font = fonts.getUIFont(18)
    local prevFont = love.graphics.getFont()
    if font then love.graphics.setFont(font) end

    local textWidth = (font and font:getWidth(abilityName)) or 0
    local textHeight = (font and font:getHeight()) or 18
    local tx = x + (castBarWidth * 0.5) - (textWidth * 0.5)
    local ty = y + (HUDLayout.CAST_BAR_HEIGHT * 0.5) - (textHeight * 0.5)

    -- Subtle shadow for readability
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.print(abilityName, tx + 1, ty + 1)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(abilityName, tx, ty)

    if prevFont then love.graphics.setFont(prevFont) end

    -- Restore color and stack
    love.graphics.setColor(r, g, b, a)
    love.graphics.pop()
end

return CastBarHUD

