local System = require("src.core.System")
local GameState = require("src.core.GameState")
local EventBus = require("src.utils.EventBus")
local CollisionUtils = require("src.utils.collision")

---@class CoinPickupSystem : System
local CoinPickupSystem = System:extend("CoinPickupSystem", {"PhysicsCollision", "Coin"})

---Create a new CoinPickupSystem
---@return CoinPickupSystem
function CoinPickupSystem.new()
    ---@class CoinPickupSystem
    local self = System.new({"PhysicsCollision", "Coin"})
    setmetatable(self, CoinPickupSystem)
    return self
end

---Update the coin pickup system
---@param dt number Delta time
function CoinPickupSystem:update(dt)
    -- Get player entity via world's cached lookup
    local playerEntity = nil
    local world = nil
    if self.entities[1] and self.entities[1]._world then
        world = self.entities[1]._world
        if world.getPlayer then
            playerEntity = world:getPlayer()
        end
    end

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

                if world then
                    world:removeEntity(coinEntity)
                end

                print(string.format("Picked up %d coin(s)! Total: %d", coinValue, GameState.getTotalCoins()))
            end
        end
    end
end

return CoinPickupSystem
