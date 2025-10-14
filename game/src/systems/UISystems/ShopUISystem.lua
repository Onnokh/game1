local System = require("src.core.System")
local fonts = require("src.utils.fonts")
local ui_text = require("src.utils.ui_text")
local gameState = require("src.core.GameState")
local AnimationModule = require("src.core.Animation")
local AnimationManager = AnimationModule.AnimationManager

---@class ShopUISystem : System
---@field ecsWorld World
---@field activeShops table
---@field mousePressed boolean
---@field mouseX number
---@field mouseY number
local ShopUISystem = System:extend("ShopUISystem", {})

function ShopUISystem.new(ecsWorld)
    ---@class ShopUISystem
    local self = System.new()
    setmetatable(self, ShopUISystem)
    self.ecsWorld = ecsWorld
    self.activeShops = {}
    self.isWorldSpace = false -- Draw in screen space for crisp UI
    self.drawOrder = 0 -- Draw below menus
    self.mousePressed = false
    self.mouseX = 0
    self.mouseY = 0

    -- Animation manager for all shop animations
    self.animationManager = AnimationManager.new()
    self.hoveredSlot = nil -- {shopEntity, slotIndex}
    self.animatingOutShops = {} -- Shops that are animating out but not in interaction range

    return self
end

function ShopUISystem:update(dt)
    -- Update all animations
    self.animationManager:update(dt)

    -- Find player entity
    local player = self.ecsWorld:getPlayer()
    if not player then
        self.activeShops = {}
        self.hoveredSlot = nil
        return
    end

    local playerPos = player:getComponent("Position")
    if not playerPos then
        self.activeShops = {}
        self.hoveredSlot = nil
        return
    end

    -- Get player center position
    local playerSprite = player:getComponent("SpriteRenderer")
    local playerCenterX = playerPos.x + (playerSprite and playerSprite.width / 2 or 0)
    local playerCenterY = playerPos.y + (playerSprite and playerSprite.height / 2 or 0)

    -- Find all shops within interaction range
    local previousActiveShops = {}
    for _, shop in ipairs(self.activeShops) do
        previousActiveShops[shop.id] = true
    end

    local shops = self.ecsWorld:getEntitiesWithTag("Shop")
    local shopsInRange = {} -- Shops currently in interaction range
    local shopsInRangeIds = {}

    for _, shop in ipairs(shops) do
        local shopPos = shop:getComponent("Position")
        local shopSprite = shop:getComponent("SpriteRenderer")

        if shopPos and shopSprite then
            -- Get shop center position
            local shopCenterX = shopPos.x + shopSprite.width / 2
            local shopCenterY = shopPos.y + shopSprite.height / 2

            -- Calculate distance
            local dx = playerCenterX - shopCenterX
            local dy = playerCenterY - shopCenterY
            local distance = math.sqrt(dx * dx + dy * dy)

            -- Check if within interaction range
            local interactionRange = shop.interactionRange or 80
            if distance <= interactionRange then
                shopsInRange[shop.id] = shop
                shopsInRangeIds[shop.id] = true

                -- Start scale-in animation for newly visible shops (only if just entered range)
                local animId = "shop_scale_" .. tostring(shop.id)
                local anim = self.animationManager:get(animId)

                if not anim and not previousActiveShops[shop.id] then
                    -- Shop just entered range, create new scale-in animation
                    self.animationManager:create(animId, 0.0, 1.0, 0.25, "outBack")
                elseif anim and anim.targetValue == 0.0 then
                    -- Shop re-entered range while animating out, reverse the animation
                    anim:reverse()
                end
            end
        end
    end

    -- Detect shops that left range and start scale-out animation
    for _, shop in ipairs(self.activeShops) do
        if not shopsInRangeIds[shop.id] and not self.animatingOutShops[shop.id] then
            -- Shop just left range, start scale-out animation
            local animId = "shop_scale_" .. tostring(shop.id)
            local anim = self.animationManager:get(animId)
            if anim and anim.targetValue == 1.0 then
                -- Reverse to scale out
                anim:reverse()
                self.animatingOutShops[shop.id] = shop
            elseif not anim then
                -- Animation was already cleaned up, create new scale-out animation from 1.0
                self.animationManager:create(animId, 1.0, 0.0, 0.25, "inQuad")
                self.animatingOutShops[shop.id] = shop
            end
        end
    end

    -- Clean up animating out shops that have finished (or no longer have an animation)
    for shopId, shop in pairs(self.animatingOutShops) do
        local animId = "shop_scale_" .. tostring(shopId)
        local anim = self.animationManager:get(animId)
        -- Remove if animation is complete or doesn't exist (was auto-cleaned)
        if not anim or anim.isComplete then
            self.animationManager:remove(animId)
            self.animatingOutShops[shopId] = nil
        end
    end

    -- Build activeShops list: shops in range + shops animating out
    self.activeShops = {}
    for shopId, shop in pairs(shopsInRange) do
        table.insert(self.activeShops, shop)
    end
    for shopId, shop in pairs(self.animatingOutShops) do
        if not shopsInRangeIds[shopId] then -- Don't add twice
            table.insert(self.activeShops, shop)
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

function ShopUISystem:updateHoveredSlot()
    -- Reset hovered slot
    self.hoveredSlot = nil

    local mouseX, mouseY = self.mouseX, self.mouseY

    -- Check each active shop's item slots
    for _, shop in ipairs(self.activeShops) do
        -- Skip shops that are animating out
        if self.animatingOutShops[shop.id] then
            goto continue
        end

        local shopPos = shop:getComponent("Position")
        local shopSprite = shop:getComponent("SpriteRenderer")
        local shopComp = shop:getComponent("Shop")

        if shopPos and shopSprite and shopComp then
            -- Convert shop world position to screen
            local shopWorldX = shopPos.x + shopSprite.width / 2
            local shopWorldY = shopPos.y
            local screenX, screenY = shopWorldX, shopWorldY

            if gameState and gameState.camera and gameState.camera.toScreen then
                screenX, screenY = gameState.camera:toScreen(shopWorldX, shopWorldY)
            end

            -- Check each of the 3 item slots
            local slotSize = 128
            local slotSpacing = 160

            for i = 1, 3 do
                local item = shopComp:getItem(i)
                if item then
                    local slotX = screenX + (i - 2) * slotSpacing - slotSize / 2
                    local slotY = screenY - 60

                    -- Check if mouse is within this slot
                    if mouseX >= slotX and mouseX <= slotX + slotSize and
                       mouseY >= slotY and mouseY <= slotY + slotSize then
                        self.hoveredSlot = {shop = shop, slotIndex = i}
                        return
                    end
                end
            end
        end
        ::continue::
    end
end

function ShopUISystem:handleMouseClick()
    local mouseX, mouseY = self.mouseX, self.mouseY

    -- Get player entity and inventory
    local player = self.ecsWorld:getPlayer()
    if not player then
        return
    end

    local playerInventory = player:getComponent("Inventory")
    if not playerInventory then
        print("[ShopUI] Player has no inventory component")
        return
    end

    -- Check each active shop's item slots
    for _, shop in ipairs(self.activeShops) do
        -- Skip shops that are animating out
        if self.animatingOutShops[shop.id] then
            goto continue
        end

        local shopPos = shop:getComponent("Position")
        local shopSprite = shop:getComponent("SpriteRenderer")
        local shopComp = shop:getComponent("Shop")

        if shopPos and shopSprite and shopComp then
            -- Convert shop world position to screen
            local shopWorldX = shopPos.x + shopSprite.width / 2
            local shopWorldY = shopPos.y
            local screenX, screenY = shopWorldX, shopWorldY

            if gameState and gameState.camera and gameState.camera.toScreen then
                screenX, screenY = gameState.camera:toScreen(shopWorldX, shopWorldY)
            end

            -- Check each of the 3 item slots
            local slotSize = 128 -- 64px item + 32px padding on each side
            local slotSpacing = 160 -- 128px slot + 32px gap between items

            for i = 1, 3 do
                local item = shopComp:getItem(i)
                if item then
                    local slotX = screenX + (i - 2) * slotSpacing - slotSize / 2
                    local slotY = screenY - 60

                    -- Check if mouse is within this slot
                    if mouseX >= slotX and mouseX <= slotX + slotSize and
                       mouseY >= slotY and mouseY <= slotY + slotSize then
                        -- Check if player has enough coins
                        local playerCoins = gameState.getTotalCoins()
                        local cost = item.cost or 0

                        if playerCoins >= cost then
                            -- Player can afford the item
                            -- Deduct coins and purchase item
                            if gameState.removeCoins(cost) then
                                -- Trigger purchase shrink animation
                                local animId = "purchase_" .. tostring(shop.id) .. "_" .. tostring(i)
                                local purchaseAnim = self.animationManager:create(animId, 1.0, 0.0, 0.25, "inBack")

                                -- Store item data and metadata on the animation for rendering
                                purchaseAnim.itemData = {
                                    id = item.id,
                                    name = item.name,
                                    cost = item.cost,
                                    spriteSheet = item.spriteSheet,
                                    spriteFrame = item.spriteFrame
                                }
                                purchaseAnim.slotIndex = i
                                purchaseAnim.shop = shop

                                -- Purchase from shop (returns item definition and removes it)
                                local purchasedItem = shopComp:purchaseItem(i)
                                if purchasedItem and purchasedItem.id then
                                    -- Add item to player's inventory using the ID from definition
                                    playerInventory:addItem(purchasedItem.id, 1)
                                    print(string.format("[ShopUI] Purchased %s for %d coins", purchasedItem.name, cost))
                                else
                                    -- Refund coins if purchase failed
                                    gameState.addCoins(cost)
                                    print(string.format("[ShopUI] Purchase failed for %s", item.name))
                                end
                            end
                        else
                            -- Not enough coins
                            print(string.format("[ShopUI] Not enough coins! Need %d, have %d", cost, playerCoins))
                        end
                        return
                    end
                end
            end
        end
        ::continue::
    end
end


function ShopUISystem:draw()
    if #self.activeShops == 0 then
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

    -- Get player's current coins for affordability checks
    local playerCoins = gameState.getTotalCoins()

    -- Slot colors
    local slotColors = {
        {255/255, 68/255, 68/255},   -- Red
        {68/255, 255/255, 68/255},   -- Green
        {68/255, 68/255, 255/255}    -- Blue
    }

    -- Draw UI for each active shop
    for _, shop in ipairs(self.activeShops) do
        local shopPos = shop:getComponent("Position")
        local shopSprite = shop:getComponent("SpriteRenderer")
        local shopComp = shop:getComponent("Shop")

        if shopPos and shopSprite and shopComp then
            -- Get shop center in world space
            local shopWorldX = shopPos.x + shopSprite.width / 2
            local shopWorldY = shopPos.y

            -- Convert to screen space
            local screenX, screenY = shopWorldX, shopWorldY
            if gameState and gameState.camera and gameState.camera.toScreen then
                screenX, screenY = gameState.camera:toScreen(shopWorldX, shopWorldY)
            end

            -- Get shop scale animation value (default to 1.0 if no animation)
            local animId = "shop_scale_" .. tostring(shop.id)
            local shopScale = self.animationManager:getValue(animId, 1.0)

            -- Apply scale transform to entire shop UI, centered at bottom center (screenX, screenY)
            love.graphics.push()
            love.graphics.translate(screenX, screenY)
            love.graphics.scale(shopScale, shopScale)
            love.graphics.translate(-screenX, -screenY)

            -- Draw 3 item slots (128x128 with 32px padding, 64px item, 32px spacing)
            local slotSize = 128 -- 64px item + 32px padding on each side
            local slotSpacing = 160 -- 128px slot + 32px gap between items

            for i = 1, 3 do
                local item = shopComp:getItem(i)
                local slotX = screenX + (i - 2) * slotSpacing - slotSize / 2
                local slotY = screenY - 60

                -- Check if this slot has a purchase animation (even if item is nil)
                local purchaseAnimId = "purchase_" .. tostring(shop.id) .. "_" .. tostring(i)
                local purchaseAnim = self.animationManager:get(purchaseAnimId)

                -- Use stored item data from animation if item was just purchased
                if not item and purchaseAnim and purchaseAnim.itemData then
                    item = purchaseAnim.itemData
                end

                if item then
                    -- Check if player can afford this item (items being purchased show as affordable)
                    local canAfford = (purchaseAnim ~= nil) or (playerCoins >= (item.cost or 0))

                    -- Calculate scale based on hover and purchase animations (for item sprite only)
                    local itemScale = 1.0

                    -- Check if this slot is being hovered (but not if it's being purchased)
                    local isHovered = self.hoveredSlot and self.hoveredSlot.shop == shop and self.hoveredSlot.slotIndex == i
                    if isHovered and not purchaseAnim then
                        itemScale = 1.1 -- Grow by 10% when hovered (no easing needed for instant hover)
                    end

                    -- Purchase animation takes priority over hover (animation value goes from 1.0 to 0.0)
                    if purchaseAnim then
                        itemScale = purchaseAnim.value
                    end

                    -- Draw black background
                    love.graphics.setColor(0, 0, 0, 0.9)
                    love.graphics.rectangle("fill", slotX, slotY, slotSize, slotSize)

                    -- Draw item sprite (64x64, with 32px padding on each side)
                    local spriteSize = 64
                    local spriteOffset = 32 -- 32px padding
                    local spriteCenterX = slotX + spriteOffset + spriteSize / 2
                    local spriteCenterY = slotY + spriteOffset + spriteSize / 2

                    -- Apply scale transform only to the item sprite
                    love.graphics.push()
                    love.graphics.translate(spriteCenterX, spriteCenterY)
                    love.graphics.scale(itemScale, itemScale)
                    love.graphics.translate(-spriteCenterX, -spriteCenterY)

                    -- Draw the item sprite if it has sprite info
                    if item.spriteSheet and item.spriteFrame then
                        local iffy = require("lib.iffy")
                        -- Desaturate if player can't afford
                        if canAfford then
                            love.graphics.setColor(1, 1, 1, 1)
                        else
                            love.graphics.setColor(0.3, 0.3, 0.3, 1)
                        end
                        -- Scale from 32x32 to 64x64 (scale = 2)
                        local scale = spriteSize / 32
                        iffy.draw(item.spriteSheet, item.spriteFrame, spriteCenterX - spriteSize/2, spriteCenterY - spriteSize/2, 0, scale, scale)
                    else
                        -- Fallback: draw colored square if no sprite
                        local color = slotColors[i] or {1, 1, 1}
                        if canAfford then
                            love.graphics.setColor(color[1], color[2], color[3], 1)
                        else
                            love.graphics.setColor(color[1] * 0.3, color[2] * 0.3, color[3] * 0.3, 1)
                        end
                        love.graphics.rectangle("fill", slotX + spriteOffset, slotY + spriteOffset, spriteSize, spriteSize)
                    end

                    -- Pop the scale transform
                    love.graphics.pop()

                    -- Draw border around entire slot (gray if can't afford, white if can)
                    if canAfford then
                        love.graphics.setColor(1, 1, 1, 1)
                    else
                        love.graphics.setColor(0.5, 0.5, 0.5, 1)
                    end
                    love.graphics.setLineWidth(2)
                    love.graphics.rectangle("line", slotX, slotY, slotSize, slotSize)
                    love.graphics.setLineWidth(1)

                    -- Draw item name above slot
                    love.graphics.setColor(1, 1, 1, 1)
                    local nameText = item.name or "Item"
                    local nameWidth = font and font:getWidth(nameText) or 0
                    local nameX = slotX + slotSize / 2
                    local nameY = slotY - 18

                    love.graphics.push()
                    love.graphics.translate(nameX, nameY)
                    ui_text.drawOutlinedText(nameText, -nameWidth / 2, 0, {1, 1, 1, 1}, {0, 0, 0, 0.8}, 1)
                    love.graphics.pop()

                    -- Draw price below slot (red if can't afford, yellow if can)
                    local priceColor = canAfford and {1, 1, 0, 1} or {1, 0, 0, 1}
                    local priceText = tostring(item.cost)
                    local priceTextWidth = font and font:getWidth(priceText) or 0

                    -- Calculate total width (coin icon + spacing + text)
                    local coinIconSize = 16 -- Coin sprite display size
                    local spacing = 4 -- Spacing between coin and number
                    local totalWidth = coinIconSize + spacing + priceTextWidth

                    -- Center the entire price display
                    local priceX = slotX + slotSize / 2 - totalWidth / 2
                    local priceY = slotY + slotSize + 6

                    -- Draw coin icon
                    local iffy = require("lib.iffy")
                    love.graphics.setColor(1, 1, 1, 1) -- Coin sprite always full color
                    local coinScale = coinIconSize / 16 -- Scale from 16px original to desired size
                    local coinCenterY = priceY + (font and font:getHeight() or 16) / 2 - coinIconSize / 2
                    iffy.draw("coin", 1, priceX, coinCenterY, 0, coinScale, coinScale)

                    -- Draw price number to the right of coin
                    local textX = priceX + coinIconSize + spacing
                    love.graphics.setColor(priceColor[1], priceColor[2], priceColor[3], priceColor[4])
                    ui_text.drawOutlinedText(priceText, textX, priceY, priceColor, {0, 0, 0, 0.8}, 1)
                else
                    -- Draw empty/sold slot with same styling
                    -- Draw black background
                    love.graphics.setColor(0, 0, 0, 0.9)
                    love.graphics.rectangle("fill", slotX, slotY, slotSize, slotSize)

                    -- Draw gray square (64x64, with 32px padding)
                    local colorSquareSize = 64
                    local colorSquareOffset = 32 -- 32px padding
                    love.graphics.setColor(0.3, 0.3, 0.3, 0.5)
                    love.graphics.rectangle("fill", slotX + colorSquareOffset, slotY + colorSquareOffset, colorSquareSize, colorSquareSize)

                    -- Draw border (dimmer for empty slots)
                    love.graphics.setColor(0.5, 0.5, 0.5, 0.5)
                    love.graphics.setLineWidth(2)
                    love.graphics.rectangle("line", slotX, slotY, slotSize, slotSize)
                    love.graphics.setLineWidth(1)
                end
            end

            -- Pop the shop scale transform
            love.graphics.pop()
        end
    end

    love.graphics.pop()

    if prevFont then love.graphics.setFont(prevFont) end
    love.graphics.setColor(r, g, b, a)
end

-- Called when mouse button is pressed
function ShopUISystem:handleMousePressed(x, y, button)
    if button == 1 then -- Left click
        self.mousePressed = true
        self.mouseX = x
        self.mouseY = y

        -- Check if click is actually on a shop UI element
        local player = self.ecsWorld:getPlayer()
        if player then
            local playerPos = player:getComponent("Position")
            local playerSprite = player:getComponent("SpriteRenderer")

            if playerPos and playerSprite then
                local playerCenterX = playerPos.x + playerSprite.width / 2
                local playerCenterY = playerPos.y + playerSprite.height / 2

                local shops = self.ecsWorld:getEntitiesWithTag("Shop")
                for _, shop in ipairs(shops) do
                    local shopPos = shop:getComponent("Position")
                    local shopSprite = shop:getComponent("SpriteRenderer")
                    local shopComp = shop:getComponent("Shop")

                    if shopPos and shopSprite and shopComp then
                        local shopCenterX = shopPos.x + shopSprite.width / 2
                        local shopCenterY = shopPos.y + shopSprite.height / 2

                        local dx = playerCenterX - shopCenterX
                        local dy = playerCenterY - shopCenterY
                        local distance = math.sqrt(dx * dx + dy * dy)

                        local interactionRange = shop.interactionRange or 80
                        if distance <= interactionRange then
                            -- Player is in range, check if click is on any shop UI element
                            local shopWorldX = shopPos.x + shopSprite.width / 2
                            local shopWorldY = shopPos.y
                            local screenX, screenY = shopWorldX, shopWorldY

                            if gameState and gameState.camera and gameState.camera.toScreen then
                                screenX, screenY = gameState.camera:toScreen(shopWorldX, shopWorldY)
                            end

                            -- Check all 3 item slots
                            local slotSize = 128
                            local slotSpacing = 160

                            for i = 1, 3 do
                                local slotX = screenX + (i - 2) * slotSpacing - slotSize / 2
                                local slotY = screenY - 60

                                -- Check if mouse is within this slot's bounds
                                if x >= slotX and x <= slotX + slotSize and
                                   y >= slotY and y <= slotY + slotSize then
                                    -- Click is on a shop UI element, consume it
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

return ShopUISystem

