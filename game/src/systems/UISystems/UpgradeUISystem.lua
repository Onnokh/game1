local System = require("src.core.System")
local fonts = require("src.utils.fonts")
local ui_text = require("src.utils.ui_text")
local AnimationModule = require("src.core.Animation")
local AnimationManager = AnimationModule.AnimationManager
local panel = require("src.ui.utils.panel")

---@class UpgradeUISystem : System
---@field ecsWorld World
---@field isOpen boolean
---@field activeCrystal Entity|nil
---@field mouseX number
---@field mouseY number
---@field hoveredSlot number|nil
local UpgradeUISystem = System:extend("UpgradeUISystem", {})

function UpgradeUISystem.new(ecsWorld)
    ---@class UpgradeUISystem
    local self = System.new()
    setmetatable(self, UpgradeUISystem)
    self.ecsWorld = ecsWorld
    self.isOpen = false
    self.activeCrystal = nil
    self.isWorldSpace = false -- Draw in screen space
    self.drawOrder = 100 -- Draw on top of most things
    self.mouseX = 0
    self.mouseY = 0
    self.hoveredSlot = nil
    self.skipButtonHovered = false

    -- Animation manager
    self.animationManager = AnimationManager.new()

    -- Listen for crystal interaction event
    local EventBus = require("src.utils.EventBus")
    EventBus.subscribe("openCrystalUpgrade", function(data)
        self:openUpgradeUI(data.crystal)
    end)

    return self
end

---Open the upgrade UI for a crystal
---@param crystal Entity The crystal entity to show upgrades for
function UpgradeUISystem:openUpgradeUI(crystal)
    self.activeCrystal = crystal
    self.isOpen = true
    self.hoveredSlot = nil

    -- Pause the game
    local GameController = require("src.core.GameController")
    GameController.setPaused(true)

    -- Stop any movement loop sounds
    local player = self.ecsWorld:getPlayer()
    if player then
        local stateMachine = player:getComponent("StateMachine")
        if stateMachine then
            local movementSound = stateMachine:getGlobalData("movementSound")
            if movementSound then
                movementSound:stop()
                stateMachine:setGlobalData("movementSound", nil)
            end
        end
    end

    -- Start fade-in animation
    self.animationManager:create("ui_fade", 0.0, 1.0, 0.2, "linear")

    print("[UpgradeUI] Opened upgrade UI for crystal " .. tostring(crystal.id))
end

---Close the upgrade UI
function UpgradeUISystem:closeUpgradeUI()
    self.activeCrystal = nil
    self.isOpen = false
    self.hoveredSlot = nil

    -- Unpause the game
    local GameController = require("src.core.GameController")
    GameController.setPaused(false)

    -- Clear animations
    self.animationManager:remove("ui_fade")

    print("[UpgradeUI] Closed upgrade UI")
end

function UpgradeUISystem:update(dt)
    if not self.isOpen then
        return
    end

    -- Update animations
    self.animationManager:update(dt)

    -- Update mouse position
    self.mouseX, self.mouseY = love.mouse.getPosition()

    -- Update hovered slot
    self:updateHoveredSlot()
end

function UpgradeUISystem:updateHoveredSlot()
    self.hoveredSlot = nil
    self.skipButtonHovered = false

    if not self.isOpen or not self.activeCrystal then
        return
    end

    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()

    -- Calculate slot positions (same as draw)
    local slotSize = 200
    local slotSpacing = 240
    local totalWidth = slotSpacing * 2 + slotSize
    local startX = (screenW - totalWidth) / 2
    local centerY = screenH / 2 - slotSize / 2

    local upgradeComp = self.activeCrystal:getComponent("Upgrade")
    if not upgradeComp then
        return
    end

    -- Check each slot
    for i = 1, 3 do
        local upgrade = upgradeComp:getUpgrade(i)
        if upgrade then
            local slotX = startX + (i - 1) * slotSpacing
            local slotY = centerY

            -- Check if mouse is within this slot
            if self.mouseX >= slotX and self.mouseX <= slotX + slotSize and
               self.mouseY >= slotY and self.mouseY <= slotY + slotSize then
                self.hoveredSlot = i
                return
            end
        end
    end

    -- Check skip button (positioned at right side of panel, 32px from edge)
    local panelPadding = 64
    local panelW = totalWidth + panelPadding * 2
    local panelX = startX - panelPadding

    local buttonWidth = 150
    local buttonHeight = 50
    local buttonX = panelX + panelW - 32 - buttonWidth
    local buttonY = centerY + slotSize + 98

    if self.mouseX >= buttonX and self.mouseX <= buttonX + buttonWidth and
       self.mouseY >= buttonY and self.mouseY <= buttonY + buttonHeight then
        self.skipButtonHovered = true
    end
end

function UpgradeUISystem:handleMouseClick()
    if not self.isOpen or not self.activeCrystal then
        return
    end

    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()

    -- Calculate slot positions (same as draw)
    local slotSize = 200
    local slotSpacing = 240
    local totalWidth = slotSpacing * 2 + slotSize
    local startX = (screenW - totalWidth) / 2
    local centerY = screenH / 2 - slotSize / 2

    -- Check skip button first (positioned at right side of panel, 32px from edge)
    local panelPadding = 64
    local panelW = totalWidth + panelPadding * 2
    local panelX = startX - panelPadding

    local buttonWidth = 150
    local buttonHeight = 50
    local buttonX = panelX + panelW - 32 - buttonWidth
    local buttonY = centerY + slotSize + 98

    if self.mouseX >= buttonX and self.mouseX <= buttonX + buttonWidth and
       self.mouseY >= buttonY and self.mouseY <= buttonY + buttonHeight then
        self:closeUpgradeUI()
        return
    end

    local player = self.ecsWorld:getPlayer()
    if not player then
        return
    end

    local upgradeComp = self.activeCrystal:getComponent("Upgrade")
    if not upgradeComp then
        return
    end

    -- Check each slot
    for i = 1, 3 do
        local upgrade = upgradeComp:getUpgrade(i)
        if upgrade then
            local slotX = startX + (i - 1) * slotSpacing
            local slotY = centerY

            -- Check if mouse is within this slot
            if self.mouseX >= slotX and self.mouseX <= slotX + slotSize and
               self.mouseY >= slotY and self.mouseY <= slotY + slotSize then
                -- Apply upgrade
                self:applyUpgrade(player, upgrade.id, i)
                return
            end
        end
    end
end

---Apply an upgrade to the player
---@param player Entity The player entity
---@param upgradeId string The upgrade ID
---@param slotIndex number The slot index that was clicked
function UpgradeUISystem:applyUpgrade(player, upgradeId, slotIndex)
    local upgradesModule = require("src.definitions.upgrades")
    local upgradeDef = upgradesModule.getUpgrade(upgradeId)

    if not upgradeDef then
        print("[UpgradeUI] Upgrade definition not found: " .. tostring(upgradeId))
        return
    end

    local tracker = player:getComponent("UpgradeTracker")
    local modifier = player:getComponent("Modifier")
    local upgradeComp = self.activeCrystal:getComponent("Upgrade")

    if not tracker or not modifier or not upgradeComp then
        print("[UpgradeUI] Missing required components")
        return
    end

    -- Check if can upgrade
    if not tracker:canUpgrade(upgradeId, upgradeDef.maxRank) then
        print(string.format("[UpgradeUI] Cannot upgrade '%s': already at max rank", upgradeDef.name))
        return
    end

    -- Get current rank for unique source ID
    local currentRank = tracker:getRank(upgradeId)
    local source = "upgrade_" .. upgradeId .. "_rank_" .. tostring(currentRank + 1)

    -- Check if this is a weapon upgrade (path starts with "Weapon.inventory.")
    local isWeaponUpgrade = upgradeDef.targetPath and upgradeDef.targetPath:match("^Weapon%.inventory%.")

    if isWeaponUpgrade then
        -- Handle weapon upgrades directly
        local weapon = player:getComponent("Weapon")
        if not weapon then
            print("[UpgradeUI] Player has no Weapon component")
            return
        end

        -- Parse the weapon path: "Weapon.inventory.weaponId.statName"
        local weaponId, statName = upgradeDef.targetPath:match("^Weapon%.inventory%.([^.]+)%.([^.]+)$")
        if not weaponId or not statName then
            print("[UpgradeUI] Invalid weapon upgrade path: " .. tostring(upgradeDef.targetPath))
            return
        end

        -- Apply weapon override directly
        weapon:setWeaponOverride(weaponId, statName, upgradeDef.modifierValue)
        print(string.format("[UpgradeUI] Applied weapon override: %s.%s = %s", weaponId, statName, tostring(upgradeDef.modifierValue)))
    else
        -- Apply regular stat modifier
        modifier:apply(player, upgradeDef.targetPath, upgradeDef.modifierType, upgradeDef.modifierValue, source)
    end

    -- Increment rank
    tracker:incrementRank(upgradeId)

    -- Select upgrade (this will regenerate the crystal's upgrades)
    upgradeComp:selectUpgrade(slotIndex, player)

    print(string.format("[UpgradeUI] Applied upgrade '%s' (Rank %d)", upgradeDef.name, currentRank + 1))

    -- Play upgrade selected sound
    local SoundManager = require("src.core.managers.SoundManager")
    SoundManager.play("upgrade_selected", 1.0)

    -- Close UI after selecting upgrade
    self:closeUpgradeUI()
end

function UpgradeUISystem:draw()
    if not self.isOpen or not self.activeCrystal then
        return
    end

    local r, g, b, a = love.graphics.getColor()

    -- Use screen space rendering
    love.graphics.push()
    love.graphics.origin()

    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()

    -- Draw semi-transparent overlay
    local fadeAlpha = self.animationManager:getValue("ui_fade", 1.0)
    love.graphics.setColor(0, 0, 0, 0.7 * fadeAlpha)
    love.graphics.rectangle("fill", 0, 0, screenW, screenH)

    -- Get font (larger for upgrade UI)
    local basePx = 16
    local font = select(1, fonts.getCameraScaled(basePx, 1, 16))
    local prevFont = love.graphics.getFont()
    if font then love.graphics.setFont(font) end

    -- Draw 3 centered squares horizontally
    local slotSize = 200
    local slotSpacing = 240
    local totalWidth = slotSpacing * 2 + slotSize
    local startX = (screenW - totalWidth) / 2
    local centerY = screenH / 2 - slotSize / 2

    local upgradeComp = self.activeCrystal:getComponent("Upgrade")
    if not upgradeComp then
        love.graphics.pop()
        if prevFont then love.graphics.setFont(prevFont) end
        love.graphics.setColor(r, g, b, a)
        return
    end

    -- Get player's upgrade tracker for showing ranks
    local player = self.ecsWorld:getPlayer()
    local tracker = player and player:getComponent("UpgradeTracker")

    -- Draw panel background around all 3 slots (including text below)
    local panelPadding = 64
    local fontHeight = font and font:getHeight() or 16
    -- Calculate total height: slotSize + gap(10) + nameHeight + gap(5) + descHeight
    local textAreaHeight = 10 + fontHeight + 5 + fontHeight
    local contentHeight = slotSize + textAreaHeight

    local panelX = startX - panelPadding
    local panelY = centerY - panelPadding
    local panelW = totalWidth + panelPadding * 2
    local panelH = contentHeight + panelPadding * 2
    panel.draw(panelX, panelY, panelW, panelH, fadeAlpha)

    -- Draw each slot
    for i = 1, 3 do
        local upgrade = upgradeComp:getUpgrade(i)
        local slotX = startX + (i - 1) * slotSpacing
        local slotY = centerY

        if upgrade then
            local isHovered = self.hoveredSlot == i

            -- Draw panel around slot with color change on hover
            local panelColor = isHovered and {1, 1, 1} or {0.75, 0.75, 0.75}
            panel.draw(slotX, slotY, slotSize, slotSize, fadeAlpha, panelColor)

            -- Draw rank panel at the top of the slot
            if tracker then
                local currentRank = tracker:getRank(upgrade.id)
                local nextRank = currentRank + 1
                local rankText = tostring(nextRank)

                -- Small panel at top left
                local rankPanelHeight = 48
                local rankPanelWidth = 48
                local rankPanelX = slotX - 24 -- Offset from left edge of the slot
                local rankPanelY = slotY + 24 -- Offset from top edge of the slot

                -- Draw rank panel using panel-015 style
                panel.draw(rankPanelX, rankPanelY, rankPanelWidth, rankPanelHeight, fadeAlpha, panelColor, "015")

                -- Draw rank text with larger font
                local rankFont = select(1, fonts.getCameraScaled(24, 1, 24))
                if rankFont then love.graphics.setFont(rankFont) end

                love.graphics.setColor(1, 1, 1, fadeAlpha)
                local rankTextWidth = rankFont and rankFont:getWidth(rankText) or 0
                local rankTextHeight = rankFont and rankFont:getHeight() or 24
                local rankTextX = rankPanelX + rankPanelWidth / 2 - rankTextWidth / 2
                local rankTextY = rankPanelY + rankPanelHeight / 2 - rankTextHeight / 2

                ui_text.drawOutlinedText(rankText, rankTextX, rankTextY, {0, 0, 0, fadeAlpha}, {0, 0, 0, 0.8 * fadeAlpha}, 1)

                -- Restore original font
                if font then love.graphics.setFont(font) end
            end

            -- Draw upgrade sprite
            local spriteSize = 128
            local spriteX = slotX + (slotSize - spriteSize) / 2
            local spriteY = slotY + 20

            if upgrade.spriteSheet and upgrade.spriteFrame then
                local iffy = require("lib.iffy")
                love.graphics.setColor(1, 1, 1, fadeAlpha)
                local scale = spriteSize / 32

                -- Apply hover scale
                if isHovered then
                    love.graphics.push()
                    local centerX = spriteX + spriteSize / 2
                    local centerY = spriteY + spriteSize / 2
                    love.graphics.translate(centerX, centerY)
                    love.graphics.scale(1.1, 1.1)
                    love.graphics.translate(-centerX, -centerY)
                    iffy.draw(upgrade.spriteSheet, upgrade.spriteFrame, spriteX, spriteY, 0, scale, scale)
                    love.graphics.pop()
                else
                    iffy.draw(upgrade.spriteSheet, upgrade.spriteFrame, spriteX, spriteY, 0, scale, scale)
                end
            end

            -- Draw upgrade name below slot
            love.graphics.setColor(1, 1, 1, fadeAlpha)
            local nameText = upgrade.name or "Upgrade"
            local nameWidth = font and font:getWidth(nameText) or 0
            local nameX = slotX + slotSize / 2 - nameWidth / 2
            local nameY = slotY + slotSize + 10

            ui_text.drawOutlinedText(nameText, nameX, nameY, {1, 1, 1, fadeAlpha}, {0, 0, 0, 0.8 * fadeAlpha}, 1)

            -- Draw description below name
            love.graphics.setColor(0.8, 0.8, 0.8, fadeAlpha)
            local descText = upgrade.description or ""
            local descWidth = font and font:getWidth(descText) or 0
            local descX = slotX + slotSize / 2 - descWidth / 2
            local descY = nameY + (font and font:getHeight() or 16) + 5

            ui_text.drawOutlinedText(descText, descX, descY, {0.8, 0.8, 0.8, fadeAlpha}, {0, 0, 0, 0.8 * fadeAlpha}, 1)
        else
            -- Draw empty slot with panel
            panel.draw(slotX, slotY, slotSize, slotSize, fadeAlpha * 0.5, {0.6, 0.6, 0.6})
        end
    end

    -- Draw skip button (positioned at right side of panel, 32px from edge)
    local buttonWidth = 150
    local buttonHeight = 50
    local buttonX = panelX + panelW - 32 - buttonWidth
    local buttonY = centerY + slotSize + 98

    -- Draw button panel with color change on hover
    local buttonColor = self.skipButtonHovered and {0.5, 0.5, 0.5} or {0.3, 0.3, 0.3}
    panel.draw(buttonX, buttonY, buttonWidth, buttonHeight, fadeAlpha, buttonColor)

    -- Draw "Skip" text
    love.graphics.setColor(1, 1, 1, fadeAlpha)
    local skipText = "Skip"
    local textWidth = font and font:getWidth(skipText) or 0
    local textHeight = font and font:getHeight() or 16
    local textX = buttonX + buttonWidth / 2 - textWidth / 2
    local textY = buttonY + buttonHeight / 2 - textHeight / 2

    ui_text.drawOutlinedText(skipText, textX, textY, {1, 1, 1, fadeAlpha}, {0, 0, 0, 0.8 * fadeAlpha}, 1)

    love.graphics.pop()

    if prevFont then love.graphics.setFont(prevFont) end
    love.graphics.setColor(r, g, b, a)
end

-- Called when mouse button is pressed
function UpgradeUISystem:handleMousePressed(x, y, button)
    if button == 1 and self.isOpen then -- Left click
        self.mouseX = x
        self.mouseY = y
        self:handleMouseClick()
        return true -- Consume the click
    end
    return false
end

-- Called when a key is pressed
function UpgradeUISystem:handleKeyPress(key)
    if self.isOpen and key == "escape" then
        self:closeUpgradeUI()
        return true -- Consume the key press
    end
    return false
end

return UpgradeUISystem
