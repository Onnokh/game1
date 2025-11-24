---@class ActionBarHUD
local ActionBarHUD = {}
local panel = require("src.ui.utils.panel")
local abilities = require("src.definitions.abilities")
local fonts = require("src.utils.fonts")

-- Action bar configuration
local SLOT_SIZE = 64
local SLOT_SPACING = 8
local SLOT_COUNT = 4
local TOTAL_WIDTH = (SLOT_SIZE * SLOT_COUNT) + (SLOT_SPACING * (SLOT_COUNT - 1))
local BOTTOM_MARGIN = 32
local KEYBIND_LABELS = {"Q", "E", "R", "F"}
local KEYBIND_OFFSET = 4 -- Gap between keybind label and slot

---Draw the action bar in screen space (centered at bottom)
---@param world World
function ActionBarHUD.draw(world)
    if not world then
        return
    end

    love.graphics.push()
    love.graphics.origin()

    local sw, sh = love.graphics.getDimensions()
    
    -- Calculate center position for action bar
    local x = sw / 2 - TOTAL_WIDTH / 2
    local y = sh - BOTTOM_MARGIN - SLOT_SIZE

    -- Get the ranged ability for slot 1
    local rangedAbility = abilities.getAbility("ranged")

    -- Draw each slot
    for i = 1, SLOT_COUNT do
        local slotX = x + (i - 1) * (SLOT_SIZE + SLOT_SPACING)
        local slotY = y

        -- Draw keybind label above the slot
        local keybindLabel = KEYBIND_LABELS[i] or tostring(i)
        local font = fonts.getUIFont(18)
        local prevFont = love.graphics.getFont()
        if font then love.graphics.setFont(font) end

        local textWidth = (font and font:getWidth(keybindLabel)) or 0
        local textHeight = (font and font:getHeight()) or 18
        local keybindX = slotX + (SLOT_SIZE / 2) - (textWidth / 2)
        local keybindY = slotY - textHeight - KEYBIND_OFFSET

        -- Shadow for keybind
        love.graphics.setColor(0, 0, 0, 0.8)
        love.graphics.print(keybindLabel, keybindX + 1, keybindY + 1)
        -- Main keybind text
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print(keybindLabel, keybindX, keybindY)

        if prevFont then love.graphics.setFont(prevFont) end

        -- Draw slot background using panel
        panel.draw(slotX, slotY, SLOT_SIZE, SLOT_SIZE, 0.9, {0.2, 0.2, 0.2}, "000")

        -- Draw slot border
        local r, g, b, a = love.graphics.getColor()
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", slotX, slotY, SLOT_SIZE, SLOT_SIZE)
        love.graphics.setColor(r, g, b, a)

        -- Draw placeholder icon or ability icon
        if i == 1 and rangedAbility then
            -- Draw placeholder for ranged ability (slot 1)
            -- Use a simple colored rectangle as placeholder
            local iconPadding = 8
            local iconSize = SLOT_SIZE - (iconPadding * 2)
            local iconX = slotX + iconPadding
            local iconY = slotY + iconPadding

            -- Draw placeholder icon with ability's glow color
            local glowColor = rangedAbility.glowColor or {1.0, 0.85, 0.6}
            love.graphics.setColor(glowColor[1], glowColor[2], glowColor[3], 0.8)
            love.graphics.rectangle("fill", iconX, iconY, iconSize, iconSize, 4, 4)
            
            -- Draw ability name text
            local font = fonts.getUIFont(16)
            local prevFont = love.graphics.getFont()
            if font then love.graphics.setFont(font) end
            
            local abilityName = rangedAbility.name or "Gun"
            local textWidth = (font and font:getWidth(abilityName)) or 0
            local textHeight = (font and font:getHeight()) or 16
            local textX = slotX + (SLOT_SIZE / 2) - (textWidth / 2)
            local textY = slotY + SLOT_SIZE - textHeight - 4

            -- Shadow
            love.graphics.setColor(0, 0, 0, 0.8)
            love.graphics.print(abilityName, textX + 1, textY + 1)
            -- Main text
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.print(abilityName, textX, textY)

            if prevFont then love.graphics.setFont(prevFont) end
        else
            -- Draw placeholder for empty slots
            local iconPadding = 8
            local iconSize = SLOT_SIZE - (iconPadding * 2)
            local iconX = slotX + iconPadding
            local iconY = slotY + iconPadding

            -- Draw placeholder rectangle
            love.graphics.setColor(0.3, 0.3, 0.3, 0.5)
            love.graphics.rectangle("fill", iconX, iconY, iconSize, iconSize, 4, 4)

            -- Draw slot number
            local font = fonts.getUIFont(20)
            local prevFont = love.graphics.getFont()
            if font then love.graphics.setFont(font) end

            local slotNumber = tostring(i)
            local textWidth = (font and font:getWidth(slotNumber)) or 0
            local textHeight = (font and font:getHeight()) or 20
            local textX = slotX + (SLOT_SIZE / 2) - (textWidth / 2)
            local textY = slotY + (SLOT_SIZE / 2) - (textHeight / 2)

            -- Shadow
            love.graphics.setColor(0, 0, 0, 0.8)
            love.graphics.print(slotNumber, textX + 1, textY + 1)
            -- Main text
            love.graphics.setColor(0.7, 0.7, 0.7, 1)
            love.graphics.print(slotNumber, textX, textY)

            if prevFont then love.graphics.setFont(prevFont) end
        end
    end

    love.graphics.pop()
end

return ActionBarHUD

