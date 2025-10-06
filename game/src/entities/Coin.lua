local Entity = require("src.core.Entity")
local Position = require("src.components.Position")
local SpriteRenderer = require("src.components.SpriteRenderer")
local PhysicsCollision = require("src.components.PhysicsCollision")
local Coin = require("src.components.Coin")
local Animator = require("src.components.Animator")
local DepthSorting = require("src.utils.depthSorting")
local GameConstants = require("src.constants")

---@class Coin
local CoinEntity = {}

---Create a new coin entity
---@param x number X position
---@param y number Y position
---@param value number|nil Coin value, defaults to 1
---@param world World|nil The ECS world to add the coin to
---@param physicsWorld table|nil The physics world for collision
---@return Entity The created coin entity
function CoinEntity.create(x, y, value, world, physicsWorld)
    local coin = Entity.new()
    coin.isCoin = true -- Flag to identify coin entities

    -- Create components
    local position = Position.new(x, y, DepthSorting.getLayerZ("LOOT")) -- Coins at loot level
    local coinComponent = Coin.new(value)

    -- Create sprite renderer for coin spritesheet (9 frames)
    local spriteRenderer = SpriteRenderer.new("coin", 16, 16) -- Assuming 16x16 coin sprites

    -- Create physics collision for coin pickup
    local physicsCollision = PhysicsCollision.new(12, 12, "sensor", 2, 2, "rectangle")
    physicsCollision.isSensor = true -- Coins are pickup sensors

    -- Create collider if physics world is available
    if physicsWorld then
        physicsCollision:createCollider(physicsWorld, x, y)
    end

    coin:addComponent("Position", position)
    coin:addComponent("SpriteRenderer", spriteRenderer)
    coin:addComponent("Animator", Animator.new("coin", {1, 2, 3, 4, 5, 6, 7, 8, 9}, 8, true))
    coin:addComponent("PhysicsCollision", physicsCollision)
    coin:addComponent("Coin", coinComponent)

    if world then
        world:addEntity(coin)
    end

    return coin
end

return CoinEntity
