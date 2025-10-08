local System = require("src.core.System")
local GameState = require("src.core.GameState")
local EventBus = require("src.utils.EventBus")
local CollisionUtils = require("src.utils.collision")

---@class CoinPickupSystem : System
local CoinPickupSystem = System:extend("CoinPickupSystem", {"PhysicsCollision", "Coin"})

---Update the coin pickup system
---@param dt number Delta time
function CoinPickupSystem:update(dt)
  if not self.world then return end

  local playerEntity = self.world:getPlayer()
  if not playerEntity then return end

	local playerPhysics = playerEntity:getComponent("PhysicsCollision")
	if not playerPhysics or not playerPhysics:hasCollider() then return end

    -- First pass: detection only (mark picked up)
    for _, coinEntity in ipairs(self.entities) do
        if not coinEntity.isPickedUp then
            local coinComponent = coinEntity:getComponent("Coin")
            local coinPhysics = coinEntity:getComponent("PhysicsCollision")
            if coinComponent and CollisionUtils.aabbOverlaps(playerPhysics, coinPhysics) then
                coinEntity.isPickedUp = true

            -- Play coin pickup sound
            if _G.SoundManager then
              _G.SoundManager.play("coin", 0.3, .7) -- Play at 50% volume to avoid being too loud
            end

            end
        end
    end

    -- Second pass: processing (update state, emit events, remove)
    for _, coinEntity in ipairs(self.entities) do
        if coinEntity.isPickedUp then
            local coinComponent = coinEntity:getComponent("Coin")
            if coinComponent then
                local coinValue = coinComponent:getValue()
                GameState.addCoins(coinValue)

                -- Determine a good screen-space anchor for the pickup popup
                local position = coinEntity:getComponent("Position")
                local sprite = coinEntity:getComponent("SpriteRenderer")
                local anchorX = position and position.x or 0
                local anchorY = position and position.y or 0
                if sprite then
                    local w = sprite.width or 16
                    anchorX = anchorX + w * 0.5
                end

                EventBus.emit("coinPickedUp", {
                    amount = coinValue,
                    total = GameState.getTotalCoins(),
                    worldX = anchorX,
                    worldY = anchorY,
                })

                if self.world then
                    self.world:removeEntity(coinEntity)
                end

                print(string.format("Picked up %d coin(s)! Total: %d", coinValue, GameState.getTotalCoins()))
            end
        end
    end
end

return CoinPickupSystem
