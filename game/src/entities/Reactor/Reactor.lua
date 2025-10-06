local Entity = require("src.core.Entity")
local Position = require("src.components.Position")
local SpriteRenderer = require("src.components.SpriteRenderer")
local Animator = require("src.components.Animator")
local PathfindingCollision = require("src.components.PathfindingCollision")
local Health = require("src.components.Health")
local HealthBar = require("src.components.HealthBar")
local Light = require("src.components.Light")
local EventBus = require("src.utils.EventBus")

---@class Reactor
local Reactor = {}

---Create a new Reactor entity (static 64x64 object)
---@param x number X position (top-left in world units)
---@param y number Y position (top-left in world units)
---@param world World ECS world to add the reactor to
---@param physicsWorld table|nil Physics world for collision
---@return Entity The created reactor entity
function Reactor.create(x, y, world, physicsWorld)

    local reactor = Entity.new()
    reactor.isReactor = true -- Flag to identify reactor entities
    local position = Position.new(x, y, 0)
    local spriteRenderer = SpriteRenderer.new(nil, 64, 64)
    local animator = Animator.new("reactor", {1, 2, 3, 4}, 4, true)
    local health = Health.new(1000)
    local healthBar = HealthBar.new(48, 4, -6)
    healthBar.alwaysVisible = true

    local collider = PathfindingCollision.new(64, 48, "static", 0, 16)
    if physicsWorld then
        collider:createCollider(physicsWorld, x, y)
    end
    local light = Light.new({
        radius = 420,
        r = 180,
        g = 220,
        b = 255,
        a = 200,
        flicker = true,
        flickerSpeed = 2.2,              -- slow breathing
        flickerRadiusAmplitude = 20,     -- gentle size pulsing
        flickerAlphaAmplitude = 25       -- gentle brightness pulsing
    })
    reactor:addComponent("Position", position)
    reactor:addComponent("SpriteRenderer", spriteRenderer)
    reactor:addComponent("Animator", animator)
    reactor:addComponent("PathfindingCollision", collider)
    reactor:addComponent("Health", health)
    reactor:addComponent("HealthBar", healthBar)
    reactor:addComponent("Light", light)


    if world then
        world:addEntity(reactor)
    end

    return reactor
end

---Handle reactor death - turn off light and add visual effects
---@param entity Entity The reactor entity that died
function Reactor.handleDeath(entity)
    print("Reactor has died - turning off light")
    -- Turn off the reactor's light
    local light = entity:getComponent("Light")
    if light then
        light.enabled = false
        print("Reactor light disabled")
    end
end

return Reactor


