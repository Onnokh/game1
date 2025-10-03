---@class Player
local Player = {}

---Create a new player entity
---@param x number X position
---@param y number Y position
---@param world World The ECS world to add the player to
---@param physicsWorld table|nil The physics world for collision
---@return Entity The created player entity
function Player.create(x, y, world, physicsWorld)
    local Entity = require("src.ecs.Entity")
    local Position = require("src.ecs.components.Position")
    local Movement = require("src.ecs.components.Movement")
    local SpriteRenderer = require("src.ecs.components.SpriteRenderer")
    local Animator = require("src.ecs.components.Animator")
    local AnimationController = require("src.ecs.components.AnimationController")
    local Collision = require("src.ecs.components.Collision")
    local GameConstants = require("src.constants")

    -- Create the player entity
    local player = Entity.new()

    -- Add Position component
    local position = Position.new(x, y, 0)
    player:addComponent("Position", position)

    -- Add Movement component
    local movement = Movement.new(GameConstants.PLAYER_SPEED, 3000, 1) -- maxSpeed, acceleration, friction
    player:addComponent("Movement", movement)

    -- Add SpriteRenderer component
    local spriteRenderer = SpriteRenderer.new(nil, 24, 24) -- width, height (24x24 sprite)
    spriteRenderer.facingMouse = true -- Enable mouse-facing
    player:addComponent("SpriteRenderer", spriteRenderer)

    -- Animator for character animations
    local animator = Animator.new("character", {1, 2}, 6, true) -- Start with idle
    player:addComponent("Animator", animator)

    -- AnimationController to switch between idle and walking
    -- Idle: frames 1-2 (row 1, cols 1-2), Walk: frames 9-12 (row 2, cols 1-4)
    local animationController = AnimationController.new(
        {1, 2},      -- idle frames
        {13, 14, 15, 16}, -- run frames (row 2, columns 1-4)
        6,           -- idle fps
        8            -- walk fps
    )
    player:addComponent("AnimationController", animationController)

    -- Add Collision component
    -- Collider centered at bottom: width 12, height 8, offsetX centers horizontally, offsetY positions at bottom
    local colliderWidth, colliderHeight = 12, 12
    local offsetX = (spriteRenderer.width - colliderWidth) / 2
    local offsetY = spriteRenderer.height - colliderHeight
    local collision = Collision.new(colliderWidth, colliderHeight, "dynamic", offsetX, offsetY)
    collision.restitution = 0.1 -- Slight bounce
    collision.friction = 0.3 -- Low friction for smooth movement
    collision.linearDamping = 0 -- No damping for direct velocity control

    -- Create collider if physics world is available
    if physicsWorld then
        collision:createCollider(physicsWorld, x, y)
    end

    player:addComponent("Collision", collision)

    -- Add the player to the world
    if world then
        world:addEntity(player)
    end

    return player
end

return Player
