local Entity = require("src.core.Entity")
local Position = require("src.components.Position")
local SpriteRenderer = require("src.components.SpriteRenderer")
local PathfindingCollision = require("src.components.PathfindingCollision")
local Shop = require("src.components.Shop")
local GroundShadow = require("src.components.GroundShadow")
local Animator = require("src.components.Animator")
local Light = require("src.components.Light")
local MinimapIcon = require("src.components.MinimapIcon")
local sprites = require("src.utils.sprites")
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
    local spriteRenderer = SpriteRenderer.new(nil, 64, 64)
    local animation = Animator.new({ sheet = 'shop', frames = {1}, fps = 1, loop = true })
    animation:setAnimation({ sheet = 'shop', frames = {1, 2, 3, 4, 5, 6, 7, 8}, fps = 8, loop = true })

    local shopComponent = Shop.new(inventory, seed, shopId)

    -- Create pathfinding collision (similar to Reactor)
    local collider = PathfindingCollision.new(64, 48, "static", 0, 16)
    if physicsWorld then
        collider:createCollider(physicsWorld, x, y)
    end

    local light = Light.new({
        { r = 255, g = 0, b = 255, radius = 48, offsetX = 36, offsetY = 16, flicker = false, flickerRadiusAmplitude = 1.2 }
    })

    -- Store interaction range as entity property for ShopUISystem
    shop.interactionRange = 80

    shop:addComponent("Position", position)
    shop:addComponent("SpriteRenderer", spriteRenderer)
    shop:addComponent("PathfindingCollision", collider)
    shop:addComponent("Animator", animation)
    shop:addComponent("Shop", shopComponent)
    shop:addComponent("Light", light)
    shop:addComponent("GroundShadow", GroundShadow.new({ alpha = .5, widthFactor = .8, heightFactor = .6, offsetY = 0 }))

    -- Add minimap icon with the siege icon
    shop:addComponent("MinimapIcon", MinimapIcon.new("shop", nil, 5, sprites.getImage("minimapShop")))

    -- Tag for easy querying
    shop:addTag("Shop")

    if world then
        world:addEntity(shop)
    end

    return shop
end

return ShopEntity

