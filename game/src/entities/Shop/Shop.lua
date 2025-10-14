local Entity = require("src.core.Entity")
local Position = require("src.components.Position")
local SpriteRenderer = require("src.components.SpriteRenderer")
local PathfindingCollision = require("src.components.PathfindingCollision")
local Shop = require("src.components.Shop")

---@class ShopEntity
local ShopEntity = {}

---Create a new Shop entity (static 64x64 object)
---@param x number X position (top-left in world units)
---@param y number Y position (top-left in world units)
---@param world World ECS world to add the shop to
---@param physicsWorld table|nil Physics world for collision
---@param inventory table|nil Optional custom inventory
---@param seed number|nil Optional seed for deterministic inventory generation
---@param shopId string|nil Optional shop identifier for unique seed per shop
---@return Entity The created shop entity
function ShopEntity.create(x, y, world, physicsWorld, inventory, seed, shopId)

    local shop = Entity.new()
    local position = Position.new(x, y, 0)
    local spriteRenderer = SpriteRenderer.new('shop', 64, 64)
    local shopComponent = Shop.new(inventory, seed, shopId)

    -- Create pathfinding collision (similar to Reactor)
    local collider = PathfindingCollision.new(64, 48, "static", 0, 16)
    if physicsWorld then
        collider:createCollider(physicsWorld, x, y)
    end

    -- Store interaction range as entity property for ShopUISystem
    shop.interactionRange = 80

    shop:addComponent("Position", position)
    shop:addComponent("SpriteRenderer", spriteRenderer)
    shop:addComponent("PathfindingCollision", collider)
    shop:addComponent("Shop", shopComponent)

    -- Tag for easy querying
    shop:addTag("Shop")

    if world then
        world:addEntity(shop)
    end

    return shop
end

return ShopEntity

