---@class TooltipSystem
---Global tooltip system for displaying tooltips in screen space
local TooltipSystem = {}

-- Tooltip configuration (constants)
local PADDING = 12
local ICON_SIZE = 72  -- Match action bar icon size (3x scale of 24px sprites)
local ICON_PADDING = 16  -- Padding between icon and text content
local TEXT_SPACING = 4
local COOLDOWN_FONT_SIZE = 12
local TITLE_FONT_SIZE = 16
local DESCRIPTION_FONT_SIZE = 14
local MAX_WIDTH = 400  -- Wider to fit text on 2 rows

-- Current tooltip data
local currentTooltip = nil

---Show a tooltip
---@param data table Tooltip data with fields: icon, title, description, cooldown, castTime, x, y
---@field icon love.Image|nil Icon to display
---@field title string Title text
---@field description string Description text
---@field cooldown string|nil Cooldown text (e.g., "6s")
---@field castTime string|nil Cast time text (e.g., "1.5s cast")
---@field x number Screen X position (tooltip will be positioned relative to this)
---@field y number Screen Y position (tooltip will be positioned relative to this)
function TooltipSystem.show(data)
    currentTooltip = data
end

---Hide the current tooltip
function TooltipSystem.hide()
    currentTooltip = nil
end

---Update tooltip position (for following mouse)
---@param x number Screen X position
---@param y number Screen Y position
function TooltipSystem.updatePosition(x, y)
    if currentTooltip then
        currentTooltip.x = x
        currentTooltip.y = y
    end
end

---Draw the tooltip (call this in screen space, after love.graphics.push/origin)
function TooltipSystem.draw()
    if not currentTooltip then
        return
    end

    local fonts = require("src.utils.fonts")
    local panel = require("src.ui.utils.panel")

    -- Get fonts
    local titleFont = fonts.getUIFont(TITLE_FONT_SIZE)
    local descFont = fonts.getUIFont(DESCRIPTION_FONT_SIZE)
    local cooldownFont = fonts.getUIFont(COOLDOWN_FONT_SIZE)
    local castTimeFont = fonts.getUIFont(DESCRIPTION_FONT_SIZE) -- Use description font size for cast time

    -- Calculate text dimensions
    local titleWidth = titleFont:getWidth(currentTooltip.title)
    local titleHeight = titleFont:getHeight()

    -- Calculate cast time dimensions if present (for width calculation)
    local castTimeWidth = 0
    if currentTooltip.castTime then
        castTimeWidth = castTimeFont:getWidth(currentTooltip.castTime)
    end

    -- Calculate total title line width (title + spacing + cast time)
    local titleLineWidth = titleWidth
    if castTimeWidth > 0 then
        titleLineWidth = titleLineWidth + TEXT_SPACING + castTimeWidth
    end

    -- Wrap description text
    local descLines = {}
    local descText = currentTooltip.description or ""
    if descText ~= "" then
        local words = {}
        for word in descText:gmatch("%S+") do
            table.insert(words, word)
        end

        local line = ""
        local availableWidth = MAX_WIDTH - (ICON_SIZE + ICON_PADDING * 2 + PADDING * 2)

        for _, word in ipairs(words) do
            local testLine = line == "" and word or line .. " " .. word
            local testWidth = descFont:getWidth(testLine)

            if testWidth <= availableWidth then
                line = testLine
            else
                if line ~= "" then
                    table.insert(descLines, line)
                end
                line = word
            end
        end
        if line ~= "" then
            table.insert(descLines, line)
        end
    end

    local descHeight = #descLines * descFont:getHeight()
    if #descLines > 1 then
        descHeight = descHeight + (#descLines - 1) * TEXT_SPACING
    end

    -- Calculate total text height (title + spacing + description)
    -- Cast time is on the same line as title, so it doesn't add to height
    local textHeight = titleHeight
    if descHeight > 0 then
        textHeight = textHeight + TEXT_SPACING + descHeight
    end

    -- Calculate tooltip dimensions
    local contentHeight = math.max(ICON_SIZE, textHeight)
    local tooltipWidth = ICON_SIZE + ICON_PADDING * 2 + PADDING * 2 + math.max(titleLineWidth, MAX_WIDTH - (ICON_SIZE + ICON_PADDING * 2 + PADDING * 2))
    local tooltipHeight = PADDING * 2 + contentHeight

    -- Position tooltip (above and to the right of the target position, with offset)
    local tooltipX = currentTooltip.x + 16
    local tooltipY = currentTooltip.y - tooltipHeight - 8

    -- Keep tooltip on screen
    local sw, sh = love.graphics.getDimensions()
    if tooltipX + tooltipWidth > sw then
        tooltipX = currentTooltip.x - tooltipWidth - 16
    end
    if tooltipY < 0 then
        tooltipY = currentTooltip.y + 8
    end
    if tooltipX < 0 then
        tooltipX = 8
    end
    if tooltipY + tooltipHeight > sh then
        tooltipY = sh - tooltipHeight - 8
    end

    -- Draw tooltip background
    panel.draw(tooltipX, tooltipY, tooltipWidth, tooltipHeight, 0.95, {0.15, 0.15, 0.15})

    -- Draw border
    local r, g, b, a = love.graphics.getColor()
    love.graphics.setColor(0.3, 0.3, 0.3, 1)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", tooltipX, tooltipY, tooltipWidth, tooltipHeight)
    love.graphics.setColor(r, g, b, a)

    -- Draw icon (left side)
    if currentTooltip.icon then
        local iconX = tooltipX + PADDING
        local iconY = tooltipY + PADDING + (contentHeight - ICON_SIZE) / 2

        -- Draw icon background (square)
        love.graphics.setColor(0.1, 0.1, 0.1, 1)
        love.graphics.rectangle("fill", iconX, iconY, ICON_SIZE, ICON_SIZE)
        love.graphics.setColor(0.2, 0.2, 0.2, 1)
        love.graphics.rectangle("line", iconX, iconY, ICON_SIZE, ICON_SIZE)

        -- Draw icon
        local iconWidth = currentTooltip.icon:getWidth()
        local iconHeight = currentTooltip.icon:getHeight()
        local scaleX = (ICON_SIZE - 4) / iconWidth
        local scaleY = (ICON_SIZE - 4) / iconHeight
        local scale = math.min(scaleX, scaleY)

        local scaledWidth = iconWidth * scale
        local scaledHeight = iconHeight * scale
        local centeredX = iconX + (ICON_SIZE / 2) - (scaledWidth / 2)
        local centeredY = iconY + (ICON_SIZE / 2) - (scaledHeight / 2)

        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(currentTooltip.icon, centeredX, centeredY, 0, scale, scale)
    end

    -- Draw text content (right of icon)
    local textX = tooltipX + PADDING + ICON_SIZE + ICON_PADDING
    local textY = tooltipY + PADDING

    -- Draw cooldown text (top right)
    if currentTooltip.cooldown then
        local prevFont = love.graphics.getFont()
        love.graphics.setFont(cooldownFont)
        local cooldownWidth = cooldownFont:getWidth(currentTooltip.cooldown)
        local cooldownX = tooltipX + tooltipWidth - PADDING - cooldownWidth
        local cooldownY = textY

        -- Shadow
        love.graphics.setColor(0, 0, 0, 0.8)
        love.graphics.print(currentTooltip.cooldown, cooldownX + 1, cooldownY + 1)
        -- Main text
        love.graphics.setColor(0.7, 0.7, 0.7, 1)
        love.graphics.print(currentTooltip.cooldown, cooldownX, cooldownY)
        love.graphics.setColor(r, g, b, a)
        if prevFont then
            love.graphics.setFont(prevFont)
        end
    end

    -- Draw title
    local prevFont = love.graphics.getFont()
    love.graphics.setFont(titleFont)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(currentTooltip.title, textX, textY)

    -- Draw cast time (after title, on the same line)
    local currentX = textX + titleWidth
    if currentTooltip.castTime then
        currentX = currentX + TEXT_SPACING
        love.graphics.setFont(castTimeFont)
        love.graphics.setColor(0.9, 0.9, 0.7, 1) -- Slightly yellow tint for cast time
        love.graphics.print(currentTooltip.castTime, currentX, textY)
    end

    -- Draw description
    local currentY = textY + titleHeight
    if #descLines > 0 then
        currentY = currentY + TEXT_SPACING
        love.graphics.setFont(descFont)
        love.graphics.setColor(0.8, 0.8, 0.8, 1)
        for i, line in ipairs(descLines) do
            love.graphics.print(line, textX, currentY + (i - 1) * (descFont:getHeight() + TEXT_SPACING))
        end
    end

    love.graphics.setColor(r, g, b, a)
    if prevFont then
        love.graphics.setFont(prevFont)
    end
end

return TooltipSystem

