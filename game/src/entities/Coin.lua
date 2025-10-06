local Entity = require("src.core.Entity")
local Position = require("src.components.Position")
local SpriteRenderer = require("src.components.SpriteRenderer")
local PhysicsCollision = require("src.components.PhysicsCollision")
local PathfindingCollision = require("src.components.PathfindingCollision")
local Coin = require("src.components.Coin")
local Animator = require("src.components.Animator")
local Movement = require("src.components.Movement")
local DepthSorting = require("src.utils.depthSorting")

---@class Coin
local CoinEntity = {}

---Create a new coin entity
---@param x number X position
---@param y number Y position
---@param value number|nil Coin value, defaults to 1
---@param world World|nil The ECS world to add the coin to
---@param physicsWorld table|nil The physics world for collision
---@param velocityX number|nil Initial X velocity, defaults to 0
---@param velocityY number|nil Initial Y velocity, defaults to 0
---@return Entity The created coin entity
function CoinEntity.create(x, y, value, world, physicsWorld, velocityX, velocityY)
    local coin = Entity.new()
    coin.isCoin = true -- Flag to identify coin entities

    -- Create components
    local position = Position.new(x, y, DepthSorting.getLayerZ("LOOT")) -- Coins at loot level
    local coinComponent = Coin.new(value)

    -- Create movement component for coin physics (low max speed, very high friction to stop quickly)
    local movement = Movement.new(100, 0, 0.9) -- maxSpeed=200, no acceleration, very high friction
    if velocityX and velocityY then
        movement:setVelocity(velocityX, velocityY)
    end

    -- Create sprite renderer for coin spritesheet (9 frames)
    local spriteRenderer = SpriteRenderer.new("coin", 16, 16) -- Original 16x16 coin sprites
    spriteRenderer.scaleX = 0.75 -- Scale down to 8x8 visual size
    spriteRenderer.scaleY = 0.75 -- Scale down to 8x8 visual size

    -- Create pathfinding collision for physics/movement (as sensor so it doesn't block movement)
    local pathfindingCollision = PathfindingCollision.new(4, 4, "dynamic", spriteRenderer.width / 2, spriteRenderer.height / 2, "circle")

    -- Create physics collision sensor for pickup detection
    local physicsCollision = PhysicsCollision.new(8, 8, "sensor", 2, 4, "circle")

    -- Create colliders if physics world is available
    if physicsWorld then
        pathfindingCollision:createCollider(physicsWorld, x, y)
        physicsCollision:createCollider(physicsWorld, x, y)

        -- Make the pathfinding collision a sensor too (so it doesn't block movement)
        if pathfindingCollision.collider and pathfindingCollision.collider.fixture then
            pathfindingCollision.collider.fixture:setSensor(true)
        end
    end

    coin:addComponent("Position", position)
    coin:addComponent("Movement", movement)
    coin:addComponent("SpriteRenderer", spriteRenderer)
    coin:addComponent("Animator", Animator.new("coin", {1, 2, 3, 4, 5, 6, 7, 8, 9}, 8, true))
    coin:addComponent("PathfindingCollision", pathfindingCollision)
    coin:addComponent("PhysicsCollision", physicsCollision)
    coin:addComponent("Coin", coinComponent)

    if world then
        world:addEntity(coin)
    end

    return coin
end

return CoinEntity
