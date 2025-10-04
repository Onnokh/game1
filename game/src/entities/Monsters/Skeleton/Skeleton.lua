---@class Skeleton
local Skeleton = {}

---Create a new skeleton enemy entity
---@param x number X position
---@param y number Y position
---@param world World The ECS world to add the skeleton to
---@param physicsWorld table|nil The physics world for collision
---@return Entity The created skeleton entity
function Skeleton.create(x, y, world, physicsWorld)
    local Entity = require("src.core.Entity")
    local Position = require("src.components.Position")
    local Movement = require("src.components.Movement")
    local SpriteRenderer = require("src.components.SpriteRenderer")
    local Collision = require("src.components.Collision")
    local StateMachine = require("src.components.StateMachine")
    local Pathfinding = require("src.components.Pathfinding")
    local GameConstants = require("src.constants")
    local SkeletonConfig = require("src.entities.Monsters.Skeleton.SkeletonConfig")
    local CastableShadow = require("src.components.CastableShadow")
    local DepthSorting = require("src.utils.depthSorting")

    -- Create the skeleton entity
    local skeleton = Entity.new()

    -- Create components
    local position = Position.new(x, y, DepthSorting.getLayerZ("GROUND")) -- Skeleton at ground level
    local movement = Movement.new(GameConstants.PLAYER_SPEED, 2000, 1) -- maxSpeed, acceleration, friction

    local spriteRenderer = SpriteRenderer.new(nil, SkeletonConfig.SPRITE_WIDTH, SkeletonConfig.SPRITE_HEIGHT)

    -- Collision component
    -- Collider centered at bottom: width 12, height 8, offsetX centers horizontally, offsetY positions at bottom
    local colliderWidth, colliderHeight = SkeletonConfig.COLLIDER_WIDTH, SkeletonConfig.COLLIDER_HEIGHT
    local colliderShape = SkeletonConfig.COLLIDER_SHAPE
    local offsetX = (spriteRenderer.width - colliderWidth) / 2
    local offsetY = spriteRenderer.height - colliderHeight - 8
    local collision = Collision.new(colliderWidth, colliderHeight, "dynamic", offsetX, offsetY, colliderShape)
    collision.restitution = SkeletonConfig.COLLIDER_RESTITUTION
    collision.friction = SkeletonConfig.COLLIDER_FRICTION
    collision.linearDamping = SkeletonConfig.COLLIDER_DAMPING

    -- Create collider if physics world is available
    if physicsWorld then
        collision:createCollider(physicsWorld, x, y)
    end

    -- Create pathfinding component
    local pathfinding = Pathfinding.new(x, y, SkeletonConfig.WANDER_RADIUS) -- 8 tile wander radius

    -- Create state machine first
    local stateMachine = StateMachine.new("idle")

    local Idle = require("src.entities.Monsters.Skeleton.states.Idle")
    local Wandering = require("src.entities.Monsters.Skeleton.states.Wandering")
    local Animator = require("src.components.Animator")

    local animator = Animator.new("skeleton", SkeletonConfig.IDLE_ANIMATION.frames, SkeletonConfig.IDLE_ANIMATION.fps, SkeletonConfig.IDLE_ANIMATION.loop)

    stateMachine:addState("idle", Idle.new())
    stateMachine:addState("wandering", Wandering.new())

    skeleton:addComponent("Position", position)
    skeleton:addComponent("Movement", movement)
    skeleton:addComponent("SpriteRenderer", spriteRenderer)
    skeleton:addComponent("Collision", collision)
    skeleton:addComponent("Pathfinding", pathfinding)
    skeleton:addComponent("StateMachine", stateMachine)
    skeleton:addComponent("Animator", animator)

    if world then
        world:addEntity(skeleton)
    end

    return skeleton
end


return Skeleton
