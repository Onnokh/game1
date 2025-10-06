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

                EventBus.emit("coinPickedUp", {
                    amount = coinValue,
                    total = GameState.getTotalCoins()
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
