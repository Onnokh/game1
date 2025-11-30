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

-- Elite variant configuration
local ELITE_SCALE = 1.2   -- Scale multiplier for elite monsters (affects sprite and colliders)
local ELITE_HEALTH_MULTIPLIER = 3
local ELITE_DAMAGE_MULTIPLIER = 2
local ELITE_KNOCKBACK_MULTIPLIER = 6
local ELITE_CHANCE = 0.05 -- Probability of spawning an elite variant (5%)
local ELITE_OUTLINE_COLOR = {r = 1, g = 0.84, b = 0, a = 0.8} -- Gold outline for elite monsters

-- Generic state modules
local GenericIdle = require("src.entities.Monsters.core.states.GenericIdle")
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

    -- Elite variant flag
    local isElite = options.isElite or false

    -- Create the monster entity
    local monster = Entity.new()
    monster:addTag(tag) -- Specific tag (e.g., "Skeleton", "Warhog")
    monster:addTag("Monster") -- Generic tag for all monsters

    -- Add Elite tag if this is an elite variant
    if isElite then
        monster:addTag("Elite")
    end

    monster.target = nil -- Current target (player)

    -- Create components
    local position = Position.new(x, y, DepthSorting.getLayerZ("GROUND"))
    local movement = Movement.new(GameConstants.PLAYER_SPEED, 2000, 1)

    local spriteRenderer = SpriteRenderer.new(nil, config.SPRITE_WIDTH, config.SPRITE_HEIGHT)

    -- Apply scaling for elite variants
    if isElite then
        spriteRenderer.scaleX = ELITE_SCALE
        spriteRenderer.scaleY = ELITE_SCALE
        -- Store the elite scale for later use by other systems
        spriteRenderer.eliteScale = ELITE_SCALE

        -- Center the scaled sprite using offset
        -- When sprite scales, it grows from top-left, so we need to offset it back
        local sizeDiffX = (spriteRenderer.width * ELITE_SCALE - spriteRenderer.width) / 2

        -- Store the base offset for later use by other systems
        spriteRenderer.baseOffsetX = -sizeDiffX
        spriteRenderer.baseOffsetY = 0  -- Don't adjust Y offset
        spriteRenderer.offsetX = -sizeDiffX
        spriteRenderer.offsetY = 0  -- Don't adjust Y offset
    else
        spriteRenderer.eliteScale = 1.0
    end

    -- Apply outline - gold for elites, config color for normal monsters
    if isElite then
        spriteRenderer:setOutline(ELITE_OUTLINE_COLOR)
    elseif config.OUTLINE_COLOR then
        -- spriteRenderer:setOutline(config.OUTLINE_COLOR)
    end

    -- PathfindingCollision component
    local colliderScale = isElite and ELITE_SCALE or 1
    local colliderWidth, colliderHeight = config.COLLIDER_WIDTH * colliderScale, config.COLLIDER_HEIGHT * colliderScale
    local colliderShape = config.COLLIDER_SHAPE

    local pfOffsetX = pathfindingOffsetX or ((spriteRenderer.width - config.COLLIDER_WIDTH) / 2)
    local basePfOffsetY = pathfindingOffsetY or (spriteRenderer.height - config.COLLIDER_HEIGHT - 8)

    -- Adjust Y offset for elite scaling - when sprite grows, its bottom edge moves down
    local pfOffsetY = basePfOffsetY
    if isElite then
        local spriteGrowth = (spriteRenderer.height * ELITE_SCALE - spriteRenderer.height) / 2
        pfOffsetY = basePfOffsetY + spriteGrowth
    end
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
    local basePhOffsetY = physicsOffsetY or (spriteRenderer.height / 2 - config.DRAW_HEIGHT / 2)

    -- Adjust Y offset for elite scaling - when sprite grows, its bottom edge moves down
    local phOffsetY = basePhOffsetY
    if isElite then
        local spriteGrowth = (spriteRenderer.height * ELITE_SCALE - spriteRenderer.height) / 2
        phOffsetY = basePhOffsetY + spriteGrowth
    end
    local physicsCollision = PhysicsCollision.new(
        config.DRAW_WIDTH * colliderScale,
        config.DRAW_HEIGHT * colliderScale,
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
    local pathfinding = Pathfinding.new(x, y, 0)

    local animator = Animator.new(config.IDLE_ANIMATION)

    -- Create health component with elite scaling
    local healthMultiplier = isElite and ELITE_HEALTH_MULTIPLIER or 1
    local health = Health.new(config.MAX_HEALTH * healthMultiplier, config.HEALTH * healthMultiplier)

    -- Create attack component with elite scaling
    local damageMultiplier = isElite and ELITE_DAMAGE_MULTIPLIER or 1
    -- Apply knockback multiplier for elite variants
    local knockbackMultiplier = isElite and ELITE_KNOCKBACK_MULTIPLIER or 1
    local attack = Attack.new(
        config.ATTACK_DAMAGE * damageMultiplier,
        (config.ATTACK_RANGE_TILES or 1.0) * GameConstants.TILE_SIZE,
        config.ATTACK_COOLDOWN,
        "ranged",
        config.ATTACK_KNOCKBACK * knockbackMultiplier
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

-- Export elite configuration
MonsterFactory.ELITE_CHANCE = ELITE_CHANCE

return MonsterFactory

