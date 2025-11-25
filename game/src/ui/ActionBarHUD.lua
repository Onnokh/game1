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

-- Get slot mapping from AbilitySystem (source of truth)
local AbilitySystem = require("src.systems.AbilitySystem")
local SLOT_ABILITY_MAP = AbilitySystem.SLOT_ABILITY_MAP

-- Cache for loaded icons
local iconCache = {}

-- Load icon from ability definition or path
local function getIcon(abilityId, iconPath)
    if not iconPath then
        return nil
    end

    -- Check cache first
    if iconCache[iconPath] then
        return iconCache[iconPath]
    end

    -- Try to load the icon
    local success, icon = pcall(love.graphics.newImage, iconPath)
    if success and icon then
        icon:setFilter("nearest", "nearest")
        iconCache[iconPath] = icon
        return icon
    end

    return nil
end

---Get cooldown progress for an ability from AbilitySystem (0 = ready, 1 = full cooldown)
---@param world World
---@param abilityId string|nil
---@return number Cooldown progress (0-1)
local function getCooldownProgress(world, abilityId)
    if not world or not abilityId then
        return 0
    end

    -- Get AbilitySystem instance
    local abilitySystem = AbilitySystem.getInstance(world)
    if not abilitySystem then
        return 0
    end

    local currentTime = love.timer.getTime()
    local abilityData = abilities.getAbility(abilityId)

    return abilitySystem:getCooldownProgress(abilityId, abilityData, currentTime)
end

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
        panel.draw(slotX, slotY, SLOT_SIZE, SLOT_SIZE, 0.9, {0.2, 0.2, 0.2})

        -- Draw slot border
        local r, g, b, a = love.graphics.getColor()
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", slotX, slotY, SLOT_SIZE, SLOT_SIZE)
        love.graphics.setColor(r, g, b, a)

        -- Get ability for this slot
        local abilityId = SLOT_ABILITY_MAP[i]
        local ability = abilityId and abilities.getAbility(abilityId) or nil

        -- Draw ability icon
        local iconPadding = 2
        local iconSize = SLOT_SIZE - (iconPadding * 2)

        -- Get icon from ability definition
        local icon = nil
        if ability and ability.icon then
            icon = getIcon(abilityId, ability.icon)
        end

        if icon then
            -- Check if the key for this slot is currently being held
            local isKeyHeld = false
            if i == 1 then
                isKeyHeld = love.keyboard.isDown("q")
            elseif i == 2 then
                isKeyHeld = love.keyboard.isDown("e")
            elseif i == 3 then
                isKeyHeld = love.keyboard.isDown("r")
            elseif i == 4 then
                isKeyHeld = love.keyboard.isDown("f")
            end

            -- Calculate scale to fit icon in slot
            local iconWidth = icon:getWidth()
            local iconHeight = icon:getHeight()
            local scaleX = iconSize / iconWidth
            local scaleY = iconSize / iconHeight
            local baseScale = math.min(scaleX, scaleY) -- Maintain aspect ratio

            -- Shrink icon by 2px when key is held
            local scale = baseScale
            if isKeyHeld then
                -- Adjust scale to make icon 2px smaller
                scale = baseScale * ((iconSize - 2) / iconSize)
            end

            -- Center the icon (account for size increase)
            local scaledWidth = iconWidth * scale
            local scaledHeight = iconHeight * scale
            local centeredX = slotX + (SLOT_SIZE / 2) - (scaledWidth / 2)
            local centeredY = slotY + (SLOT_SIZE / 2) - (scaledHeight / 2)

            -- Draw icon with natural colors (no tint)
            local r, g, b, a = love.graphics.getColor()
            if ability then
                -- Full brightness for ability slot
                love.graphics.setColor(1, 1, 1, 1)
            else
                -- Dimmed for empty slots
                love.graphics.setColor(0.5, 0.5, 0.5, 0.8)
            end

            love.graphics.draw(icon, centeredX, centeredY, 0, scale, scale)
            love.graphics.setColor(r, g, b, a)
        end

        -- Draw cooldown overlay if ability is on cooldown
        if abilityId then
            local cooldownProgress = getCooldownProgress(world, abilityId)
            if cooldownProgress > 0 then
                -- Calculate overlay height based on cooldown progress
                -- As cooldown progresses (1 -> 0), overlay slides down (revealing icon from bottom to top)
                local overlayHeight = SLOT_SIZE * cooldownProgress

                if overlayHeight > 0 then
                    -- Save current color
                    local prevR, prevG, prevB, prevA = love.graphics.getColor()

                    -- Draw dark overlay from bottom, sliding down (position at bottom and grow upward)
                    local overlayY = slotY + SLOT_SIZE - overlayHeight
                    local overlayAlpha = 0.7 -- Dark overlay opacity

                    love.graphics.setColor(0, 0, 0, overlayAlpha)
                    love.graphics.rectangle("fill", slotX, overlayY, SLOT_SIZE, overlayHeight)

                    -- Restore color
                    love.graphics.setColor(prevR, prevG, prevB, prevA)
                end
            end
        end
    end

    love.graphics.pop()
end

return ActionBarHUD

