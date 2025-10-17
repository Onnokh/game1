local System = require("src.core.System")
local fonts = require("src.utils.fonts")
local ui_text = require("src.utils.ui_text")
local AnimationModule = require("src.core.Animation")
local AnimationManager = AnimationModule.AnimationManager

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

    -- Check skip button
    local buttonWidth = 150
    local buttonHeight = 50
    local buttonX = (screenW - buttonWidth) / 2
    local buttonY = centerY + slotSize + 100

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

    -- Check skip button first
    local buttonWidth = 150
    local buttonHeight = 50
    local buttonX = (screenW - buttonWidth) / 2
    local buttonY = centerY + slotSize + 100

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

    -- Apply modifier
    modifier:apply(player, upgradeDef.targetPath, upgradeDef.modifierType, upgradeDef.modifierValue, source)

    -- Increment rank
    tracker:incrementRank(upgradeId)

    -- Select upgrade (this will regenerate the crystal's upgrades)
    upgradeComp:selectUpgrade(slotIndex, player)

    print(string.format("[UpgradeUI] Applied upgrade '%s' (Rank %d)", upgradeDef.name, currentRank + 1))

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

    -- Draw each slot
    for i = 1, 3 do
        local upgrade = upgradeComp:getUpgrade(i)
        local slotX = startX + (i - 1) * slotSpacing
        local slotY = centerY

        if upgrade then
            local isHovered = self.hoveredSlot == i

            -- Draw background
            love.graphics.setColor(0, 0, 0, 0.95 * fadeAlpha)
            love.graphics.rectangle("fill", slotX, slotY, slotSize, slotSize)

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

            -- Draw border
            if isHovered then
                love.graphics.setColor(1, 1, 1, fadeAlpha)
                love.graphics.setLineWidth(4)
            else
                love.graphics.setColor(0.7, 0.7, 0.7, fadeAlpha)
                love.graphics.setLineWidth(2)
            end
            love.graphics.rectangle("line", slotX, slotY, slotSize, slotSize)
            love.graphics.setLineWidth(1)

            -- Draw upgrade name with rank below slot
            love.graphics.setColor(1, 1, 1, fadeAlpha)
            local rankText = ""
            if tracker then
                local currentRank = tracker:getRank(upgrade.id)
                rankText = string.format(" (Rank %d)", currentRank + 1)
            end
            local nameText = (upgrade.name or "Upgrade") .. rankText
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
            -- Draw empty slot
            love.graphics.setColor(0, 0, 0, 0.5 * fadeAlpha)
            love.graphics.rectangle("fill", slotX, slotY, slotSize, slotSize)

            -- Draw border
            love.graphics.setColor(0.3, 0.3, 0.3, 0.5 * fadeAlpha)
            love.graphics.setLineWidth(2)
            love.graphics.rectangle("line", slotX, slotY, slotSize, slotSize)
            love.graphics.setLineWidth(1)
        end
    end

    -- Draw skip button
    local buttonWidth = 150
    local buttonHeight = 50
    local buttonX = (screenW - buttonWidth) / 2
    local buttonY = centerY + slotSize + 100

    -- Draw button background
    if self.skipButtonHovered then
        love.graphics.setColor(0.2, 0.2, 0.2, 0.95 * fadeAlpha)
    else
        love.graphics.setColor(0, 0, 0, 0.95 * fadeAlpha)
    end
    love.graphics.rectangle("fill", buttonX, buttonY, buttonWidth, buttonHeight)

    -- Draw button border
    if self.skipButtonHovered then
        love.graphics.setColor(1, 1, 1, fadeAlpha)
        love.graphics.setLineWidth(4)
    else
        love.graphics.setColor(0.7, 0.7, 0.7, fadeAlpha)
        love.graphics.setLineWidth(2)
    end
    love.graphics.rectangle("line", buttonX, buttonY, buttonWidth, buttonHeight)
    love.graphics.setLineWidth(1)

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

return UpgradeUISystem
