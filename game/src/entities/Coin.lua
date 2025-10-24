local Entity = require("src.core.Entity")
local Position = require("src.components.Position")
local SpriteRenderer = require("src.components.SpriteRenderer")
local PhysicsCollision = require("src.components.PhysicsCollision")
local PathfindingCollision = require("src.components.PathfindingCollision")
local Coin = require("src.components.Coin")
local Animator = require("src.components.Animator")
local Movement = require("src.components.Movement")
local DepthSorting = require("src.utils.depthSorting")
local GroundShadow = require("src.components.GroundShadow")

---@class Coin
local CoinEntity = {}


-- OKH: Todo: add instancing to reduce memory usage / performance.

---Create a new coin entity
---@param x number X position
---@param y number Y position
---@param world World|nil The ECS world to add the coin to
---@param physicsWorld table|nil The physics world for collision
---@param options table|nil Optional parameters {value, attractorRadius, velocityX, velocityY}
---@return Entity The created coin entity
function CoinEntity.create(x, y, world, physicsWorld, options)
    options = options or {}
    ---@class CoinEntity : Entity
    local coin = Entity.new()
    coin:addTag("Coin") -- Tag to identify coin entities

    -- Create components
    local position = Position.new(x, y, DepthSorting.getLayerZ("LOOT")) -- Coins at loot level
    local coinComponent = Coin.new(options.value, options.attractorRadius)

    -- Create movement component for coin physics (low max speed, very high friction to stop quickly)
    local movement = Movement.new(100, 0, 0.9) -- maxSpeed=200, no acceleration, very high friction
    if options.velocityX and options.velocityY then
        movement:setVelocity(options.velocityX, options.velocityY)
    end

    -- Create sprite renderer for coin spritesheet (9 frames)
    local spriteRenderer = SpriteRenderer.new(nil, 16, 16) -- Use nil for animated sprites
    spriteRenderer.scaleX = .5 -- Scale down to 8x8 visual size
    spriteRenderer.scaleY = .5 -- Scale down to 8x8 visual size

    -- Small subtle ground shadow for coin
    local groundShadow = GroundShadow.new({ alpha = .75, widthFactor = 0.8, heightFactor = 0.18, offsetY = 2 })

    -- Create pathfinding collision to match physics collision footprint (8x8 circle at offset 2,4)
    local pathfindingCollision = PathfindingCollision.new(8, 8, "dynamic", 2, 4, "circle")

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
    coin:addComponent("GroundShadow", groundShadow)
    coin:addComponent("Animator", Animator.new({ layers = {"coin"}, frames = {1, 2, 3, 4, 5, 6, 7, 8, 9}, fps = 12, loop = true }))
    coin:addComponent("PathfindingCollision", pathfindingCollision)
    coin:addComponent("PhysicsCollision", physicsCollision)
    coin:addComponent("Coin", coinComponent)

    if world then
        world:addEntity(coin)
    end

    return coin
end

return CoinEntity
