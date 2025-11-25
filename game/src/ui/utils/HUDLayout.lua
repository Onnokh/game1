---@class HUDLayout
---Centralized layout constants and calculations for HUD elements
local HUDLayout = {}

-- Action bar constants (source of truth)
HUDLayout.ACTION_BAR_SLOT_SIZE = 72
HUDLayout.ACTION_BAR_SLOT_SPACING = 16
HUDLayout.ACTION_BAR_SLOT_COUNT = 4
HUDLayout.ACTION_BAR_TOTAL_WIDTH = (HUDLayout.ACTION_BAR_SLOT_SIZE * HUDLayout.ACTION_BAR_SLOT_COUNT) + (HUDLayout.ACTION_BAR_SLOT_SPACING * (HUDLayout.ACTION_BAR_SLOT_COUNT - 1))
HUDLayout.ACTION_BAR_BOTTOM_MARGIN = 124

-- Unitframe constants
HUDLayout.UNITFRAME_PORTRAIT_SIZE = 96
HUDLayout.UNITFRAME_BAR_WIDTH = 300
HUDLayout.UNITFRAME_BAR_HEIGHT = 32
HUDLayout.UNITFRAME_MANA_BAR_WIDTH = math.floor(HUDLayout.UNITFRAME_BAR_WIDTH * 2 / 3) -- 2/3rd of health bar width
HUDLayout.UNITFRAME_MANA_BAR_HEIGHT = 24
HUDLayout.UNITFRAME_GAP_FROM_ACTION_BAR = 64
HUDLayout.UNITFRAME_PORTRAIT_OVERLAP = 10
HUDLayout.UNITFRAME_BAR_SPACING = 0
HUDLayout.UNITFRAME_VERTICAL_OFFSET = -8 -- Vertical offset for unitframe (negative = up)

-- Experience bar constants
HUDLayout.EXP_BAR_HEIGHT = 12
HUDLayout.EXP_BAR_GAP_BELOW = 64

-- Cast bar constants
HUDLayout.CAST_BAR_HEIGHT = 24
HUDLayout.CAST_BAR_GAP_ABOVE = 128 -- Gap above action bar

---Get action bar position (centered at bottom)
---@param screenWidth number
---@param screenHeight number
---@return number x X position
---@return number y Y position
function HUDLayout.getActionBarPosition(screenWidth, screenHeight)
    local x = screenWidth / 2 - HUDLayout.ACTION_BAR_TOTAL_WIDTH / 2
    local y = screenHeight - HUDLayout.ACTION_BAR_BOTTOM_MARGIN - HUDLayout.ACTION_BAR_SLOT_SIZE
    return x, y
end

---Get unitframe positions and dimensions
---@param screenWidth number
---@param screenHeight number
---@param actionBarX number Action bar X position
---@param actionBarY number Action bar Y position
---@return table Positions: {portraitX, portraitY, barX, barY, manaBarY, unitframeCenterY, unitframeWidth}
function HUDLayout.getUnitframePositions(screenWidth, screenHeight, actionBarX, actionBarY)
    -- Calculate unitframe center Y (vertically centered with action bar, plus offset)
    local unitframeCenterY = actionBarY + HUDLayout.ACTION_BAR_SLOT_SIZE / 2 + HUDLayout.UNITFRAME_VERTICAL_OFFSET

    -- Calculate bar positions
    local totalBarHeight = HUDLayout.UNITFRAME_BAR_HEIGHT + HUDLayout.UNITFRAME_MANA_BAR_HEIGHT + HUDLayout.UNITFRAME_BAR_SPACING
    local barX = actionBarX - HUDLayout.UNITFRAME_GAP_FROM_ACTION_BAR - HUDLayout.UNITFRAME_BAR_WIDTH
    local portraitX = barX - HUDLayout.UNITFRAME_PORTRAIT_SIZE + HUDLayout.UNITFRAME_PORTRAIT_OVERLAP
    local portraitY = unitframeCenterY - HUDLayout.UNITFRAME_PORTRAIT_SIZE / 2
    local barY = unitframeCenterY - totalBarHeight / 2
    local manaBarY = barY + HUDLayout.UNITFRAME_BAR_HEIGHT + HUDLayout.UNITFRAME_BAR_SPACING

    -- Calculate unitframe width (from portrait left edge to bars right edge)
    local unitframeLeft = portraitX
    local unitframeRight = barX + HUDLayout.UNITFRAME_BAR_WIDTH
    local unitframeWidth = unitframeRight - unitframeLeft

    return {
        portraitX = portraitX,
        portraitY = portraitY,
        barX = barX,
        barY = barY,
        manaBarY = manaBarY,
        unitframeCenterY = unitframeCenterY,
        unitframeWidth = unitframeWidth
    }
end

---Get experience bar position and dimensions
---@param screenWidth number
---@param screenHeight number
---@param actionBarX number Action bar X position
---@param actionBarY number Action bar Y position
---@param unitframeWidth number Unitframe width
---@return number x X position
---@return number y Y position
---@return number width Bar width
function HUDLayout.getExperienceBarPosition(screenWidth, screenHeight, actionBarX, actionBarY, unitframeWidth)
    -- Width = (UnitFrame width) * 2 + action bar width + (gap * 2)
    local expBarWidth = (unitframeWidth * 2) + HUDLayout.ACTION_BAR_TOTAL_WIDTH + (HUDLayout.UNITFRAME_GAP_FROM_ACTION_BAR * 2)
    local expBarX = screenWidth / 2 - expBarWidth / 2 -- Center on screen
    local expBarY = actionBarY + HUDLayout.ACTION_BAR_SLOT_SIZE + HUDLayout.EXP_BAR_GAP_BELOW
    return expBarX, expBarY, expBarWidth
end

---Get cast bar position (above action bar)
---@param screenWidth number
---@param screenHeight number
---@param actionBarX number Action bar X position
---@param actionBarY number Action bar Y position
---@return number x X position
---@return number y Y position
---@return number width Bar width
function HUDLayout.getCastBarPosition(screenWidth, screenHeight, actionBarX, actionBarY)
    local castBarWidth = HUDLayout.ACTION_BAR_TOTAL_WIDTH -- Same width as action bar
    local castBarX = screenWidth / 2 - castBarWidth / 2 -- Center on screen
    local castBarY = actionBarY - HUDLayout.CAST_BAR_GAP_ABOVE - HUDLayout.CAST_BAR_HEIGHT
    return castBarX, castBarY, castBarWidth
end

return HUDLayout

