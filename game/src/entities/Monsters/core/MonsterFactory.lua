---@class MonsterFactory
---Factory for creating monster entities with shared setup logic
local MonsterFactory = {}

local Entity = require("src.core.Entity")
local Position = require("src.components.Position")
local Movement = require("src.components.Movement")
local SpriteRenderer = require("src.components.SpriteRenderer")
local PathfindingCollision = require("src.components.PathfindingCollision")
local PhysicsCollision = require("src.components.PhysicsCollision")
local StateMachine = require("src.components.StateMachine")
local Pathfinding = require("src.components.Pathfinding")
local GameConstants = require("src.constants")
local Attack = require("src.components.Attack")
local Health = require("src.components.Health")
local HealthBar = require("src.components.HealthBar")
local DropTable = require("src.components.DropTable")
local DepthSorting = require("src.utils.depthSorting")
local GroundShadow = require("src.components.GroundShadow")
local Animator = require("src.components.Animator")
local MonsterBehaviors = require("src.entities.Monsters.core.MonsterBehaviors")

-- Generic state modules
local GenericIdle = require("src.entities.Monsters.core.states.GenericIdle")
local GenericWandering = require("src.entities.Monsters.core.states.GenericWandering")
local GenericChasing = require("src.entities.Monsters.core.states.GenericChasing")
local GenericAttacking = require("src.entities.Monsters.core.states.GenericAttacking")
local GenericDying = require("src.entities.Monsters.core.states.GenericDying")

---Create a monster entity with shared setup
---@param options table Configuration options for the monster
---@return Entity The created monster entity
function MonsterFactory.create(options)
    -- Required options
    local x = options.x
    local y = options.y
    local world = options.world
    local physicsWorld = options.physicsWorld
    local config = options.config -- Monster config (e.g., SkeletonConfig, WarhogConfig)
    local tag = options.tag -- e.g., "Skeleton", "Warhog"

    -- Optional overrides
    local pathfindingOffsetX = options.pathfindingOffsetX
    local pathfindingOffsetY = options.pathfindingOffsetY or config.PATHFINDING_OFFSET_Y
    local physicsOffsetX = options.physicsOffsetX
    local physicsOffsetY = options.physicsOffsetY

    -- Optional custom states (if you want to override specific behaviors)
    local customStates = options.customStates or {}

    -- Optional custom state selector (if you want to override state priority logic)
    local customStateSelector = options.stateSelector

    -- Create the monster entity
    local monster = Entity.new()
    monster:addTag(tag) -- Specific tag (e.g., "Skeleton", "Warhog")
    monster:addTag("Monster") -- Generic tag for all monsters
    monster.target = nil -- Current target (player or reactor)

    -- Create components
    local position = Position.new(x, y, DepthSorting.getLayerZ("GROUND"))
    local movement = Movement.new(GameConstants.PLAYER_SPEED, 2000, 1)

    local spriteRenderer = SpriteRenderer.new(nil, config.SPRITE_WIDTH, config.SPRITE_HEIGHT)

    -- PathfindingCollision component
    local colliderWidth, colliderHeight = config.COLLIDER_WIDTH, config.COLLIDER_HEIGHT
    local colliderShape = config.COLLIDER_SHAPE
    local pfOffsetX = pathfindingOffsetX or ((spriteRenderer.width - colliderWidth) / 2)
    local pfOffsetY = pathfindingOffsetY or (spriteRenderer.height - colliderHeight - 8)
    local pathfindingCollision = PathfindingCollision.new(
        colliderWidth,
        colliderHeight,
        "dynamic",
        pfOffsetX,
        pfOffsetY,
        colliderShape
    )
    pathfindingCollision.restitution = config.COLLIDER_RESTITUTION
    pathfindingCollision.friction = config.COLLIDER_FRICTION
    pathfindingCollision.linearDamping = config.COLLIDER_DAMPING

    -- PhysicsCollision component
    local phOffsetX = physicsOffsetX or (spriteRenderer.width / 2 - config.DRAW_WIDTH / 2)
    local phOffsetY = physicsOffsetY or (spriteRenderer.height / 2 - config.DRAW_HEIGHT / 2)
    local physicsCollision = PhysicsCollision.new(
        config.DRAW_WIDTH,
        config.DRAW_HEIGHT,
        "dynamic",
        phOffsetX,
        phOffsetY,
        "rectangle"
    )
    physicsCollision.restitution = config.COLLIDER_RESTITUTION
    physicsCollision.friction = config.COLLIDER_FRICTION
    physicsCollision.linearDamping = config.COLLIDER_DAMPING

    -- Create colliders if physics world is available
    if physicsWorld then
        pathfindingCollision:createCollider(physicsWorld, x, y)
        physicsCollision:createCollider(physicsWorld, x, y)
    end

    -- Create pathfinding component
    local pathfinding = Pathfinding.new(x, y, config.WANDER_RADIUS)

    local animator = Animator.new(config.IDLE_ANIMATION)

    -- Create health component
    local health = Health.new(config.MAX_HEALTH, config.HEALTH)
    local attack = Attack.new(
        config.ATTACK_DAMAGE,
        (config.ATTACK_RANGE_TILES or 1.0) * GameConstants.TILE_SIZE,
        config.ATTACK_COOLDOWN,
        "melee",
        config.ATTACK_KNOCKBACK
    )

    -- Create health bar component
    local healthBar = HealthBar.new(16, 2, 0)
    local groundShadow = GroundShadow.new({ alpha = 0.3, widthFactor = 0.9, heightFactor = 0.2, offsetY = 0 })

    -- Create drop table component for loot drops
    local dropTable = DropTable.new()
    dropTable:addDrop("coin", 1, 3, 1.0) -- 100% chance to drop 1-3 coins

    -- Create state machine with priority-based state selection
    -- Use custom state selector if provided, otherwise use shared behavior
    local stateMachine = StateMachine.new("idle", {
        stateSelector = customStateSelector or function(entity, dt)
            return MonsterBehaviors.selectState(entity, dt, config)
        end
    })

    -- Add states (use custom states if provided, otherwise use generic ones)
    stateMachine:addState("idle", customStates.idle or GenericIdle.new(config))
    stateMachine:addState("wandering", customStates.wandering or GenericWandering.new(config))
    stateMachine:addState("chasing", customStates.chasing or GenericChasing.new(config))
    stateMachine:addState("attacking", customStates.attacking or GenericAttacking.new(config))
    stateMachine:addState("dying", customStates.dying or GenericDying.new(config))

    monster:addComponent("Position", position)
    monster:addComponent("Movement", movement)
    monster:addComponent("SpriteRenderer", spriteRenderer)
    monster:addComponent("PathfindingCollision", pathfindingCollision)
    monster:addComponent("PhysicsCollision", physicsCollision)
    monster:addComponent("Pathfinding", pathfinding)
    monster:addComponent("StateMachine", stateMachine)
    monster:addComponent("Animator", animator)
    monster:addComponent("Health", health)
    monster:addComponent("HealthBar", healthBar)
    monster:addComponent("Attack", attack)
    monster:addComponent("DropTable", dropTable)
    monster:addComponent("GroundShadow", groundShadow)

    if world then
        world:addEntity(monster)
    end

    return monster
end

return MonsterFactory

