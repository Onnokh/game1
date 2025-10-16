local Entity = require("src.core.Entity")
local Position = require("src.components.Position")
local SpriteRenderer = require("src.components.SpriteRenderer")
local PathfindingCollision = require("src.components.PathfindingCollision")
-- local Crystal = require("src.components.Crystal")
local GroundShadow = require("src.components.GroundShadow")
local Animator = require("src.components.Animator")
local Light = require("src.components.Light")

---@class CrystalEntity
local CrystalEntity = {}

---Create a new Crystal entity (static 64x64 object)
---@param x number X position (top-left in world units)
---@param y number Y position (top-left in world units)
---@param world World ECS world to add the shop to
---@param physicsWorld table|nil Physics world for collision
---@param inventory table|nil Optional custom inventory
---@param seed number|nil Optional seed for deterministic inventory generation
---@param shopId string|nil Optional shop identifier for unique seed per shop
---@return Entity The created shop entity
function CrystalEntity.create(x, y, world, physicsWorld, inventory, seed, shopId)

    local crystal = Entity.new()
    local position = Position.new(x, y, 0)
    local spriteRenderer = SpriteRenderer.new(nil, 112, 112)
    local animation = Animator.new({ sheet = 'crystal', frames = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14}, fps = 16, loop = true })

    -- local crystalComponent = Crystal.new(inventory, seed, shopId)

    -- Create pathfinding collision (similar to Reactor)
    local collider = PathfindingCollision.new(112, 64, "static", 0, 48)
    if physicsWorld then
        collider:createCollider(physicsWorld, x, y)
    end

    -- local light = Light.new({
    --     { r = 255, g = 0, b = 255, radius = 48, offsetX = 56, offsetY = 32, flicker = false, flickerRadiusAmplitude = 1.2 }
    -- })

    -- Store interaction range as entity property for ShopUISystem
    crystal.interactionRange = 80

    crystal:addComponent("Position", position)
    crystal:addComponent("SpriteRenderer", spriteRenderer)
    crystal:addComponent("PathfindingCollision", collider)
    crystal:addComponent("Animator", animation)
    -- crystal:addComponent("Crystal", crystalComponent)
    -- crystal:addComponent("Light", light)

    -- Tag for easy querying
    crystal:addTag("Crystal")

    if world then
        world:addEntity(crystal)
    end

    return crystal
end

return CrystalEntity

