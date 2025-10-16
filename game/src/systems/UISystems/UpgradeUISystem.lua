local System = require("src.core.System")
local fonts = require("src.utils.fonts")
local ui_text = require("src.utils.ui_text")
local gameState = require("src.core.GameState")
local AnimationModule = require("src.core.Animation")
local AnimationManager = AnimationModule.AnimationManager

---@class UpgradeUISystem : System
---@field ecsWorld World
---@field activeCrystals table
---@field mousePressed boolean
---@field mouseX number
---@field mouseY number
local UpgradeUISystem = System:extend("UpgradeUISystem", {})

function UpgradeUISystem.new(ecsWorld)
    ---@class UpgradeUISystem
    local self = System.new()
    setmetatable(self, UpgradeUISystem)
    self.ecsWorld = ecsWorld
    self.activeCrystals = {}
    self.isWorldSpace = false -- Draw in screen space for crisp UI
    self.drawOrder = 0 -- Draw below menus
    self.mousePressed = false
    self.mouseX = 0
    self.mouseY = 0

    -- Animation manager for all crystal animations
    self.animationManager = AnimationManager.new()
    self.hoveredSlot = nil -- {crystalEntity, slotIndex}
    self.animatingOutCrystals = {} -- Crystals that are animating out but not in interaction range

    return self
end

function UpgradeUISystem:update(dt)
    -- Update all animations
    self.animationManager:update(dt)

    -- Find player entity
    local player = self.ecsWorld:getPlayer()
    if not player then
        self.activeCrystals = {}
        self.hoveredSlot = nil
        return
    end

    local playerPos = player:getComponent("Position")
    if not playerPos then
        self.activeCrystals = {}
        self.hoveredSlot = nil
        return
    end

    -- Get player center position
    local playerSprite = player:getComponent("SpriteRenderer")
    local playerCenterX = playerPos.x + (playerSprite and playerSprite.width / 2 or 0)
    local playerCenterY = playerPos.y + (playerSprite and playerSprite.height / 2 or 0)

    -- Find all crystals within interaction range
    local previousActiveCrystals = {}
    for _, crystal in ipairs(self.activeCrystals) do
        previousActiveCrystals[crystal.id] = true
    end

    local crystals = self.ecsWorld:getEntitiesWithTag("Crystal")
    local crystalsInRange = {} -- Crystals currently in interaction range
    local crystalsInRangeIds = {}

    for _, crystal in ipairs(crystals) do
        local crystalPos = crystal:getComponent("Position")
        local crystalSprite = crystal:getComponent("SpriteRenderer")

        if crystalPos and crystalSprite then
            -- Get crystal center position
            local crystalCenterX = crystalPos.x + crystalSprite.width / 2
            local crystalCenterY = crystalPos.y + crystalSprite.height / 2

            -- Calculate distance
            local dx = playerCenterX - crystalCenterX
            local dy = playerCenterY - crystalCenterY
            local distance = math.sqrt(dx * dx + dy * dy)

            -- Check if within interaction range
            local interactionRange = crystal.interactionRange or 80
            if distance <= interactionRange then
                crystalsInRange[crystal.id] = crystal
                crystalsInRangeIds[crystal.id] = true

                -- Start scale-in animation for newly visible crystals
                local animId = "crystal_scale_" .. tostring(crystal.id)
                local anim = self.animationManager:get(animId)

                if not anim and not previousActiveCrystals[crystal.id] then
                    -- Crystal just entered range, create new scale-in animation
                    self.animationManager:create(animId, 0.0, 1.0, 0.25, "outBack")
                elseif anim and anim.targetValue == 0.0 then
                    -- Crystal re-entered range while animating out, reverse the animation
                    anim:reverse()
                end
            end
        end
    end

    -- Detect crystals that left range and start scale-out animation
    for _, crystal in ipairs(self.activeCrystals) do
        if not crystalsInRangeIds[crystal.id] and not self.animatingOutCrystals[crystal.id] then
            -- Crystal just left range, start scale-out animation
            local animId = "crystal_scale_" .. tostring(crystal.id)
            local anim = self.animationManager:get(animId)
            if anim and anim.targetValue == 1.0 then
                -- Reverse to scale out
                anim:reverse()
                self.animatingOutCrystals[crystal.id] = crystal
            elseif not anim then
                -- Animation was already cleaned up, create new scale-out animation from 1.0
                self.animationManager:create(animId, 1.0, 0.0, 0.25, "inQuad")
                self.animatingOutCrystals[crystal.id] = crystal
            end
        end
    end

    -- Clean up animating out crystals that have finished
    for crystalId, crystal in pairs(self.animatingOutCrystals) do
        local animId = "crystal_scale_" .. tostring(crystalId)
        local anim = self.animationManager:get(animId)
        -- Remove if animation is complete or doesn't exist (was auto-cleaned)
        if not anim or anim.isComplete then
            self.animationManager:remove(animId)
            self.animatingOutCrystals[crystalId] = nil
        end
    end

    -- Build activeCrystals list: crystals in range + crystals animating out
    self.activeCrystals = {}
    for crystalId, crystal in pairs(crystalsInRange) do
        table.insert(self.activeCrystals, crystal)
    end
    for crystalId, crystal in pairs(self.animatingOutCrystals) do
        if not crystalsInRangeIds[crystalId] then -- Don't add twice
            table.insert(self.activeCrystals, crystal)
        end
    end

    -- Update hovered slot based on mouse position
    self:updateHoveredSlot()

    -- Handle mouse clicks
    if self.mousePressed and love.mouse.isDown(1) then
        self:handleMouseClick()
        self.mousePressed = false -- Only process once per click
    end

    -- Update mouse position for next frame
    self.mouseX, self.mouseY = love.mouse.getPosition()
end

function UpgradeUISystem:updateHoveredSlot()
    -- Reset hovered slot
    self.hoveredSlot = nil

    local mouseX, mouseY = self.mouseX, self.mouseY

    -- Check each active crystal's upgrade slots
    for _, crystal in ipairs(self.activeCrystals) do
        -- Skip crystals that are animating out
        if self.animatingOutCrystals[crystal.id] then
            goto continue
        end

        local crystalPos = crystal:getComponent("Position")
        local crystalSprite = crystal:getComponent("SpriteRenderer")
        local upgradeComp = crystal:getComponent("Upgrade")

        if crystalPos and crystalSprite and upgradeComp then
            -- Convert crystal world position to screen
            local crystalWorldX = crystalPos.x + crystalSprite.width / 2
            local crystalWorldY = crystalPos.y
            local screenX, screenY = crystalWorldX, crystalWorldY

            if gameState and gameState.camera and gameState.camera.toScreen then
                screenX, screenY = gameState.camera:toScreen(crystalWorldX, crystalWorldY)
            end

            -- Check each of the 3 upgrade slots
            local slotSize = 128
            local slotSpacing = 160

            for i = 1, 3 do
                local upgrade = upgradeComp:getUpgrade(i)
                if upgrade then
                    local slotX = screenX + (i - 2) * slotSpacing - slotSize / 2
                    local slotY = screenY - 60

                    -- Check if mouse is within this slot
                    if mouseX >= slotX and mouseX <= slotX + slotSize and
                       mouseY >= slotY and mouseY <= slotY + slotSize then
                        self.hoveredSlot = {crystal = crystal, slotIndex = i}
                        return
                    end
                end
            end
        end
        ::continue::
    end
end

function UpgradeUISystem:handleMouseClick()
    local mouseX, mouseY = self.mouseX, self.mouseY

    -- Get player entity
    local player = self.ecsWorld:getPlayer()
    if not player then
        return
    end

    local playerTracker = player:getComponent("UpgradeTracker")
    local playerModifier = player:getComponent("Modifier")

    if not playerTracker then
        print("[UpgradeUI] Player has no UpgradeTracker component")
        return
    end

    if not playerModifier then
        print("[UpgradeUI] Player has no Modifier component")
        return
    end

    -- Check each active crystal's upgrade slots
    for _, crystal in ipairs(self.activeCrystals) do
        -- Skip crystals that are animating out
        if self.animatingOutCrystals[crystal.id] then
            goto continue
        end

        local crystalPos = crystal:getComponent("Position")
        local crystalSprite = crystal:getComponent("SpriteRenderer")
        local upgradeComp = crystal:getComponent("Upgrade")

        if crystalPos and crystalSprite and upgradeComp then
            -- Convert crystal world position to screen
            local crystalWorldX = crystalPos.x + crystalSprite.width / 2
            local crystalWorldY = crystalPos.y
            local screenX, screenY = crystalWorldX, crystalWorldY

            if gameState and gameState.camera and gameState.camera.toScreen then
                screenX, screenY = gameState.camera:toScreen(crystalWorldX, crystalWorldY)
            end

            -- Check each of the 3 upgrade slots
            local slotSize = 128
            local slotSpacing = 160

            for i = 1, 3 do
                local upgrade = upgradeComp:getUpgrade(i)
                if upgrade then
                    local slotX = screenX + (i - 2) * slotSpacing - slotSize / 2
                    local slotY = screenY - 60

                    -- Check if mouse is within this slot
                    if mouseX >= slotX and mouseX <= slotX + slotSize and
                       mouseY >= slotY and mouseY <= slotY + slotSize then
                        -- Apply upgrade
                        self:applyUpgrade(player, crystal, upgrade.id, i)
                        return
                    end
                end
            end
        end
        ::continue::
    end
end

---Apply an upgrade to the player
---@param player Entity The player entity
---@param crystal Entity The crystal entity
---@param upgradeId string The upgrade ID
---@param slotIndex number The slot index that was clicked
function UpgradeUISystem:applyUpgrade(player, crystal, upgradeId, slotIndex)
    local upgradesModule = require("src.definitions.upgrades")
    local upgradeDef = upgradesModule.getUpgrade(upgradeId)

    if not upgradeDef then
        print("[UpgradeUI] Upgrade definition not found: " .. tostring(upgradeId))
        return
    end

    local tracker = player:getComponent("UpgradeTracker")
    local modifier = player:getComponent("Modifier")
    local upgradeComp = crystal:getComponent("Upgrade")

    if not tracker or not modifier or not upgradeComp then
        print("[UpgradeUI] Missing required components")
        return
    end

    -- Check if can upgrade
    if not tracker:canUpgrade(upgradeId, upgradeDef.maxRank) then
        print(string.format("[UpgradeUI] Cannot upgrade '%s': already at max rank", upgradeDef.name))
        return
    end

    -- Trigger purchase shrink animation
    local animId = "purchase_" .. tostring(crystal.id) .. "_" .. tostring(slotIndex)
    local purchaseAnim = self.animationManager:create(animId, 1.0, 0.0, 0.25, "inBack")

    if purchaseAnim then
        -- Store upgrade data on the animation for rendering (as custom fields)
        ---@diagnostic disable-next-line: inject-field
        purchaseAnim.upgradeData = {
            id = upgradeDef.id,
            name = upgradeDef.name,
            description = upgradeDef.description,
            spriteSheet = upgradeDef.spriteSheet,
            spriteFrame = upgradeDef.spriteFrame
        }
        ---@diagnostic disable-next-line: inject-field
        purchaseAnim.slotIndex = slotIndex
        ---@diagnostic disable-next-line: inject-field
        purchaseAnim.crystal = crystal
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
end

function UpgradeUISystem:draw()
    if #self.activeCrystals == 0 then
        return
    end

    local r, g, b, a = love.graphics.getColor()

    -- Use screen space rendering for crisp UI
    love.graphics.push()
    love.graphics.origin()

    -- Get camera scale for font sizing
    local cameraScale = (gameState and gameState.camera and gameState.camera.scale) or 1
    local basePx = 6
    local font = select(1, fonts.getCameraScaled(basePx, cameraScale, 8))
    local prevFont = love.graphics.getFont()
    if font then love.graphics.setFont(font) end

    -- Slot colors
    local slotColors = {
        {255/255, 68/255, 68/255},   -- Red
        {68/255, 255/255, 68/255},   -- Green
        {68/255, 68/255, 255/255}    -- Blue
    }

    -- Draw UI for each active crystal
    for _, crystal in ipairs(self.activeCrystals) do
        local crystalPos = crystal:getComponent("Position")
        local crystalSprite = crystal:getComponent("SpriteRenderer")
        local upgradeComp = crystal:getComponent("Upgrade")

        if crystalPos and crystalSprite and upgradeComp then
            -- Get crystal center in world space
            local crystalWorldX = crystalPos.x + crystalSprite.width / 2
            local crystalWorldY = crystalPos.y

            -- Convert to screen space
            local screenX, screenY = crystalWorldX, crystalWorldY
            if gameState and gameState.camera and gameState.camera.toScreen then
                screenX, screenY = gameState.camera:toScreen(crystalWorldX, crystalWorldY)
            end

            -- Get crystal scale animation value (default to 1.0 if no animation)
            local animId = "crystal_scale_" .. tostring(crystal.id)
            local crystalScale = self.animationManager:getValue(animId, 1.0)

            -- Apply scale transform to entire crystal UI
            love.graphics.push()
            love.graphics.translate(screenX, screenY)
            love.graphics.scale(crystalScale, crystalScale)
            love.graphics.translate(-screenX, -screenY)

            -- Draw 3 upgrade slots
            local slotSize = 128
            local slotSpacing = 160

            -- Get player's upgrade tracker for showing ranks
            local player = self.ecsWorld:getPlayer()
            local tracker = player and player:getComponent("UpgradeTracker")

            for i = 1, 3 do
                local upgrade = upgradeComp:getUpgrade(i)
                local slotX = screenX + (i - 2) * slotSpacing - slotSize / 2
                local slotY = screenY - 60

                -- Check if this slot has a purchase animation
                local purchaseAnimId = "purchase_" .. tostring(crystal.id) .. "_" .. tostring(i)
                local purchaseAnim = self.animationManager:get(purchaseAnimId)

                -- Use stored upgrade data from animation if upgrade was just selected
                ---@diagnostic disable-next-line: undefined-field
                if not upgrade and purchaseAnim and purchaseAnim.upgradeData then
                    ---@diagnostic disable-next-line: undefined-field
                    upgrade = purchaseAnim.upgradeData
                end

                if upgrade then
                    -- Calculate scale based on hover and purchase animations
                    local itemScale = 1.0

                    -- Check if this slot is being hovered
                    local isHovered = self.hoveredSlot and self.hoveredSlot.crystal == crystal and self.hoveredSlot.slotIndex == i
                    if isHovered and not purchaseAnim then
                        itemScale = 1.1 -- Grow by 10% when hovered
                    end

                    -- Purchase animation takes priority
                    if purchaseAnim then
                        itemScale = purchaseAnim.value
                    end

                    -- Draw black background
                    love.graphics.setColor(0, 0, 0, 0.9)
                    love.graphics.rectangle("fill", slotX, slotY, slotSize, slotSize)

                    -- Draw upgrade sprite
                    local spriteSize = 64
                    local spriteOffset = 32
                    local spriteCenterX = slotX + spriteOffset + spriteSize / 2
                    local spriteCenterY = slotY + spriteOffset + spriteSize / 2

                    -- Apply scale transform only to the upgrade sprite
                    love.graphics.push()
                    love.graphics.translate(spriteCenterX, spriteCenterY)
                    love.graphics.scale(itemScale, itemScale)
                    love.graphics.translate(-spriteCenterX, -spriteCenterY)

                    -- Draw the upgrade sprite if it has sprite info
                    if upgrade.spriteSheet and upgrade.spriteFrame then
                        local iffy = require("lib.iffy")
                        love.graphics.setColor(1, 1, 1, 1)
                        local scale = spriteSize / 32
                        iffy.draw(upgrade.spriteSheet, upgrade.spriteFrame, spriteCenterX - spriteSize/2, spriteCenterY - spriteSize/2, 0, scale, scale)
                    else
                        -- Fallback: draw colored square if no sprite
                        local color = slotColors[i] or {1, 1, 1}
                        love.graphics.setColor(color[1], color[2], color[3], 1)
                        love.graphics.rectangle("fill", slotX + spriteOffset, slotY + spriteOffset, spriteSize, spriteSize)
                    end

                    -- Pop the scale transform
                    love.graphics.pop()

                    -- Draw border around entire slot
                    love.graphics.setColor(1, 1, 1, 1)
                    love.graphics.setLineWidth(2)
                    love.graphics.rectangle("line", slotX, slotY, slotSize, slotSize)
                    love.graphics.setLineWidth(1)

                    -- Draw upgrade name with rank above slot
                    love.graphics.setColor(1, 1, 1, 1)
                    local rankText = ""
                    if tracker then
                        local currentRank = tracker:getRank(upgrade.id)
                        rankText = string.format(" (Rank %d)", currentRank + 1)
                    end
                    local nameText = (upgrade.name or "Upgrade") .. rankText
                    local nameWidth = font and font:getWidth(nameText) or 0
                    local nameX = slotX + slotSize / 2
                    local nameY = slotY - 18

                    love.graphics.push()
                    love.graphics.translate(nameX, nameY)
                    ui_text.drawOutlinedText(nameText, -nameWidth / 2, 0, {1, 1, 1, 1}, {0, 0, 0, 0.8}, 1)
                    love.graphics.pop()

                    -- Draw description below slot
                    love.graphics.setColor(0.8, 0.8, 0.8, 1)
                    local descText = upgrade.description or ""
                    local descWidth = font and font:getWidth(descText) or 0
                    local descX = slotX + slotSize / 2
                    local descY = slotY + slotSize + 6

                    love.graphics.push()
                    love.graphics.translate(descX, descY)
                    ui_text.drawOutlinedText(descText, -descWidth / 2, 0, {0.8, 0.8, 0.8, 1}, {0, 0, 0, 0.8}, 1)
                    love.graphics.pop()
                else
                    -- Draw empty slot
                    love.graphics.setColor(0, 0, 0, 0.9)
                    love.graphics.rectangle("fill", slotX, slotY, slotSize, slotSize)

                    -- Draw gray square
                    local colorSquareSize = 64
                    local colorSquareOffset = 32
                    love.graphics.setColor(0.3, 0.3, 0.3, 0.5)
                    love.graphics.rectangle("fill", slotX + colorSquareOffset, slotY + colorSquareOffset, colorSquareSize, colorSquareSize)

                    -- Draw border
                    love.graphics.setColor(0.5, 0.5, 0.5, 0.5)
                    love.graphics.setLineWidth(2)
                    love.graphics.rectangle("line", slotX, slotY, slotSize, slotSize)
                    love.graphics.setLineWidth(1)
                end
            end

            -- Pop the crystal scale transform
            love.graphics.pop()
        end
    end

    love.graphics.pop()

    if prevFont then love.graphics.setFont(prevFont) end
    love.graphics.setColor(r, g, b, a)
end

-- Called when mouse button is pressed
function UpgradeUISystem:handleMousePressed(x, y, button)
    if button == 1 then -- Left click
        self.mousePressed = true
        self.mouseX = x
        self.mouseY = y

        -- Check if click is on a crystal UI element
        local player = self.ecsWorld:getPlayer()
        if player then
            local playerPos = player:getComponent("Position")
            local playerSprite = player:getComponent("SpriteRenderer")

            if playerPos and playerSprite then
                local playerCenterX = playerPos.x + playerSprite.width / 2
                local playerCenterY = playerPos.y + playerSprite.height / 2

                local crystals = self.ecsWorld:getEntitiesWithTag("Crystal")
                for _, crystal in ipairs(crystals) do
                    local crystalPos = crystal:getComponent("Position")
                    local crystalSprite = crystal:getComponent("SpriteRenderer")
                    local upgradeComp = crystal:getComponent("Upgrade")

                    if crystalPos and crystalSprite and upgradeComp then
                        local crystalCenterX = crystalPos.x + crystalSprite.width / 2
                        local crystalCenterY = crystalPos.y + crystalSprite.height / 2

                        local dx = playerCenterX - crystalCenterX
                        local dy = playerCenterY - crystalCenterY
                        local distance = math.sqrt(dx * dx + dy * dy)

                        local interactionRange = crystal.interactionRange or 80
                        if distance <= interactionRange then
                            -- Player is in range, check if click is on any crystal UI element
                            local crystalWorldX = crystalPos.x + crystalSprite.width / 2
                            local crystalWorldY = crystalPos.y
                            local screenX, screenY = crystalWorldX, crystalWorldY

                            if gameState and gameState.camera and gameState.camera.toScreen then
                                screenX, screenY = gameState.camera:toScreen(crystalWorldX, crystalWorldY)
                            end

                            -- Check all 3 upgrade slots
                            local slotSize = 128
                            local slotSpacing = 160

                            for i = 1, 3 do
                                local slotX = screenX + (i - 2) * slotSpacing - slotSize / 2
                                local slotY = screenY - 60

                                -- Check if mouse is within this slot's bounds
                                if x >= slotX and x <= slotX + slotSize and
                                   y >= slotY and y <= slotY + slotSize then
                                    -- Click is on a crystal UI element, consume it
                                    return true
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return false
end

return UpgradeUISystem

