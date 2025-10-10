local Entity = require("src.core.Entity")
local Position = require("src.components.Position")
local SpriteRenderer = require("src.components.SpriteRenderer")
local Animator = require("src.components.Animator")
local PathfindingCollision = require("src.components.PathfindingCollision")
local Health = require("src.components.Health")
local HealthBar = require("src.components.HealthBar")
local Light = require("src.components.Light")
local Interactable = require("src.components.Interactable")

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
    local position = Position.new(x, y, 0)
    local spriteRenderer = SpriteRenderer.new('reactor-light', 96, 96)
    local animator = Animator.new({ sheet = "reactor", frames = {1}, fps = 4, loop = true })
    local health = Health.new(1000)
    local healthBar = HealthBar.new(48, 4, -6)
    healthBar.alwaysVisible = true

    local collider = PathfindingCollision.new(96, 48, "static", 0, 48)
    if physicsWorld then
        collider:createCollider(physicsWorld, x, y)
    end
    local light = Light.new({
      {
        radius = 140,
        r = 180,
        g = 220,
        b = 255,
        a = 120,
        offsetX = 20,
        offsetY = 40,
        flicker = true,
        flickerRadiusAmplitude = 15,     -- gentle size pulsing
    },
    {
      radius = 140,
      r = 180,
      g = 220,
      b = 255,
      a = 120,
      offsetX = 76,
      offsetY = 40,
      flicker = true,
      flickerRadiusAmplitude = 20,     -- gentle size pulsing
  }
    })

    -- Create interactable component for reactor
    local interactable = Interactable.new(
        60, -- interaction range (larger than default since reactor is big)
        function(playerEntity, reactorEntity)
            -- Switch to Siege phase
            local GameController = require("src.core.GameController")
            GameController.switchPhase("Siege")
            print("Switched to Siege phase!")
        end,
        "Press E to skip the day" -- interaction text
    )

    reactor:addComponent("Position", position)
    reactor:addComponent("Animator", animator)
    reactor:addComponent("SpriteRenderer", spriteRenderer)
    reactor:addComponent("PathfindingCollision", collider)
    reactor:addComponent("Health", health)
    reactor:addComponent("HealthBar", healthBar)
    reactor:addComponent("Light", light)
    reactor:addComponent("Interactable", interactable)

    -- Tag for easy querying
    reactor:addTag("Reactor")


    if world then
        world:addEntity(reactor)
    end

    return reactor
end

---Handle reactor death - turn off light and add visual effects
---@param entity Entity The reactor entity that died
function Reactor.handleDeath(entity)
    print("Reactor has died - turning off light")
    -- Turn off the reactor's light(s)
    local light = entity:getComponent("Light")
    if light and light.lights then
        for i, lightConfig in ipairs(light.lights) do
            lightConfig.enabled = false
        end
        print("Reactor light(s) disabled")
    end
end

return Reactor


