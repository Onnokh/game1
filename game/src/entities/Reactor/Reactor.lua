---@class Reactor
local Reactor = {}

---Create a new Reactor entity (static 64x64 object)
---@param x number X position (top-left in world units)
---@param y number Y position (top-left in world units)
---@param world World ECS world to add the reactor to
---@param physicsWorld table|nil Physics world for collision
---@return Entity The created reactor entity
function Reactor.create(x, y, world, physicsWorld)
    local Entity = require("src.core.Entity")
    local Position = require("src.components.Position")
    local SpriteRenderer = require("src.components.SpriteRenderer")
    local Animator = require("src.components.Animator")
    local PathfindingCollision = require("src.components.PathfindingCollision")
    local CastableShadow = require("src.components.CastableShadow")

    local reactor = Entity.new()

    local position = Position.new(x, y, 0)
    local spriteRenderer = SpriteRenderer.new(nil, 64, 64)
    local animator = Animator.new("reactor", {1}, 1, true)

    local collider = PathfindingCollision.new(64, 48, "static", 0, 16)
    if physicsWorld then
        collider:createCollider(physicsWorld, x, y)
    end

    local shadow = CastableShadow.new({
        shape = "rectangle",
        width = 64,
        height = 64,
        offsetX = 0,
        offsetY = 0,
    })

    reactor:addComponent("Position", position)
    reactor:addComponent("SpriteRenderer", spriteRenderer)
    reactor:addComponent("Animator", animator)
    reactor:addComponent("PathfindingCollision", collider)

    if world then
        world:addEntity(reactor)
    end

    return reactor
end

return Reactor


