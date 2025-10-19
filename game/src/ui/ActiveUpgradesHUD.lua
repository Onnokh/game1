---@class ActiveUpgradesHUD
local ActiveUpgradesHUD = {}
local fonts = require("src.utils.fonts")
local ui_text = require("src.utils.ui_text")
local panel = require("src.ui.utils.panel")

---Draw the player's active upgrades on the right side of the screen
---@param world World
function ActiveUpgradesHUD.draw(world)
    if not world or not world.entities then
        return
    end

    local player = world.getPlayer and world:getPlayer() or nil
    if not player then
        return
    end

    local upgradeTracker = player:getComponent("UpgradeTracker")
    if not upgradeTracker then
        return
    end

    -- Get all active upgrades
    local allRanks = upgradeTracker:getAllRanks()

    -- Count how many upgrades we have
    local upgradeCount = 0
    for _ in pairs(allRanks) do
        upgradeCount = upgradeCount + 1
    end

    if upgradeCount == 0 then
        return -- No upgrades to display
    end

    love.graphics.push()
    love.graphics.origin()

    local sw, sh = love.graphics.getDimensions()
    local marginX = 32
    local marginY = 32
    local iconSize = 64
    local rankBadgeSize = 32
    local verticalSpacing = 8
    local nameOffset = 8 -- Gap between name and icon panel

    -- Load upgrades module to get upgrade definitions
    local upgradesModule = require("src.definitions.upgrades")

    -- Get font for upgrade names
    local baseSize = 14
    local font = select(1, fonts.getCameraScaled(baseSize, 1, baseSize))
    local prevFont = love.graphics.getFont()
    if font then love.graphics.setFont(font) end

    local r, g, b, a = love.graphics.getColor()

    -- Position from top right
    local startX = sw - marginX - iconSize
    local startY = marginY

    -- Draw each upgrade
    local index = 0
    for upgradeId, rank in pairs(allRanks) do
        if rank > 0 then -- Only show upgrades that have been taken
            local upgradeDef = upgradesModule.getUpgrade(upgradeId)

            if upgradeDef then
                local yPos = startY + index * (iconSize + verticalSpacing)

                -- Draw icon panel background
                panel.draw(startX, yPos, iconSize, iconSize, 1.0, {0.2, 0.2, 0.2})

                -- Draw upgrade sprite/icon
                if upgradeDef.spriteSheet and upgradeDef.spriteFrame then
                    local iffy = require("lib.iffy")
                    love.graphics.setColor(1, 1, 1, 1)

                    -- Calculate scale to fit icon within panel (leaving some padding)
                    local iconPadding = 8
                    local targetSize = iconSize - iconPadding * 2
                    local scale = targetSize / 32 -- Assuming 32x32 sprites

                    local iconX = startX + iconPadding
                    local iconY = yPos + iconPadding

                    iffy.draw(upgradeDef.spriteSheet, upgradeDef.spriteFrame, iconX, iconY, 0, scale, scale)
                end

                -- Draw rank badge (top-left corner of icon, offset by -16px)
                local badgeX = startX - 16
                local badgeY = yPos - 16
                panel.draw(badgeX, badgeY, rankBadgeSize, rankBadgeSize, 1.0, {0.8, 0.6, 0.2}, "015")

                -- Draw rank number
                local rankFont = select(1, fonts.getCameraScaled(16, 1, 16))
                if rankFont then love.graphics.setFont(rankFont) end

                love.graphics.setColor(1, 1, 1, 1)
                local rankText = tostring(rank)
                local rankTextWidth = rankFont and rankFont:getWidth(rankText) or 0
                local rankTextHeight = rankFont and rankFont:getHeight() or 16
                local rankTextX = badgeX + rankBadgeSize / 2 - rankTextWidth / 2
                local rankTextY = badgeY + rankBadgeSize / 2 - rankTextHeight / 2

                ui_text.drawOutlinedText(rankText, rankTextX, rankTextY, {1, 1, 1, 1}, {0, 0, 0, 0.8}, 1)

                -- Restore font for name
                if font then love.graphics.setFont(font) end

                -- Draw upgrade name to the left of the icon
                love.graphics.setColor(1, 1, 1, 1)
                local nameText = upgradeDef.name or "Upgrade"
                local nameWidth = font and font:getWidth(nameText) or 0
                local nameHeight = font and font:getHeight() or baseSize
                local nameX = startX - nameOffset - nameWidth
                local nameY = yPos + iconSize / 2 - nameHeight / 2

                ui_text.drawOutlinedText(nameText, nameX, nameY, {1, 1, 1, 1}, {0, 0, 0, 0.8}, 1)

                index = index + 1
            end
        end
    end

    -- Restore font and color
    if prevFont then love.graphics.setFont(prevFont) end
    love.graphics.setColor(r, g, b, a)
    love.graphics.pop()
end

return ActiveUpgradesHUD

