local Entity = require("src.core.Entity")
local Position = require("src.components.Position")
local Movement = require("src.components.Movement")
local SpriteRenderer = require("src.components.SpriteRenderer")
local PathfindingCollision = require("src.components.PathfindingCollision")
local PhysicsCollision = require("src.components.PhysicsCollision")
local StateMachine = require("src.components.StateMachine")
local Pathfinding = require("src.components.Pathfinding")
local GameConstants = require("src.constants")
local WarhogConfig = require("src.entities.Monsters.Warhog.WarhogConfig")
local Attack = require("src.components.Attack")
local Health = require("src.components.Health")
local HealthBar = require("src.components.HealthBar")
local DropTable = require("src.components.DropTable")
local DepthSorting = require("src.utils.depthSorting")
local GroundShadow = require("src.components.GroundShadow")

local Idle = require("src.entities.Monsters.Warhog.states.Idle")
local Wandering = require("src.entities.Monsters.Warhog.states.Wandering")
local Chasing = require("src.entities.Monsters.Warhog.states.Chasing")
local Attacking = require("src.entities.Monsters.Warhog.states.Attacking")
local Dying = require("src.entities.Monsters.Warhog.states.Dying")
local Animator = require("src.components.Animator")

---@class Warhog
local Warhog = {}

---Create a new warhog enemy entity
---@param x number X position
---@param y number Y position
---@param world World The ECS world to add the warhog to
---@param physicsWorld table|nil The physics world for collision
---@return Entity The created warhog entity
function Warhog.create(x, y, world, physicsWorld)

    -- Create the warhog entity
    local warhog = Entity.new()
    warhog:addTag("Warhog")
    warhog.target = nil -- Current target (player or reactor)

    -- Create components
    local position = Position.new(x, y, DepthSorting.getLayerZ("GROUND")) -- Warhog at ground level
    local movement = Movement.new(GameConstants.PLAYER_SPEED, 2000, 1) -- maxSpeed, acceleration, friction

    local spriteRenderer = SpriteRenderer.new(nil, WarhogConfig.SPRITE_WIDTH, WarhogConfig.SPRITE_HEIGHT)
    -- Center the 64x64 sprite (offset to align with 32x32 entity center)

    -- PathfindingCollision component (for pathfinding and physics collision)
    -- Collider centered at bottom: width 12, height 8, offsetX centers horizontally, offsetY positions at bottom
    local colliderWidth, colliderHeight = WarhogConfig.COLLIDER_WIDTH, WarhogConfig.COLLIDER_HEIGHT
    local colliderShape = WarhogConfig.COLLIDER_SHAPE
    local offsetX = (spriteRenderer.width - colliderWidth) / 2
    local offsetY = spriteRenderer.height - colliderHeight - 18
    local pathfindingCollision = PathfindingCollision.new(colliderWidth, colliderHeight, "dynamic", offsetX, offsetY, colliderShape)
    pathfindingCollision.restitution = WarhogConfig.COLLIDER_RESTITUTION
    pathfindingCollision.friction = WarhogConfig.COLLIDER_FRICTION
    pathfindingCollision.linearDamping = WarhogConfig.COLLIDER_DAMPING

    -- PhysicsCollision component (for physics interactions only) - use sprite size
    local physicsCollision = PhysicsCollision.new(
      WarhogConfig.DRAW_WIDTH,
      WarhogConfig.DRAW_HEIGHT,
      "dynamic",
      spriteRenderer.width / 2 - WarhogConfig.DRAW_WIDTH / 2 -2,
      spriteRenderer.height / 2 - WarhogConfig.DRAW_HEIGHT / 2 + 8,
      "rectangle"
    )
    physicsCollision.restitution = WarhogConfig.COLLIDER_RESTITUTION
    physicsCollision.friction = WarhogConfig.COLLIDER_FRICTION
    physicsCollision.linearDamping = WarhogConfig.COLLIDER_DAMPING

    -- Create colliders if physics world is available
    if physicsWorld then
        pathfindingCollision:createCollider(physicsWorld, x, y)
        physicsCollision:createCollider(physicsWorld, x, y)
    end

    -- Create pathfinding component
    local pathfinding = Pathfinding.new(x, y, WarhogConfig.WANDER_RADIUS) -- 8 tile wander radius

    local animator = Animator.new(WarhogConfig.IDLE_ANIMATION)

    -- Create health component
    local health = Health.new(WarhogConfig.MAX_HEALTH, WarhogConfig.HEALTH)
    local attack = Attack.new(WarhogConfig.ATTACK_DAMAGE, (WarhogConfig.ATTACK_RANGE_TILES or 1.0) * GameConstants.TILE_SIZE, WarhogConfig.ATTACK_COOLDOWN, "melee", WarhogConfig.ATTACK_KNOCKBACK)

    -- Create health bar component (16x2 pixels, positioned above warhog)
    local healthBar = HealthBar.new(16, 2, 0)
    local groundShadow = GroundShadow.new({ alpha = 0.3, widthFactor = 0.9, heightFactor = 0.2, offsetY = 0 })

    -- Create drop table component for loot drops (0-3 coins)
    local dropTable = DropTable.new()
    dropTable:addDrop("coin", 1, 3, 1.0) -- 100% chance to drop 1-3 coins

     -- Create state machine with priority-based state selection
     local stateMachine = StateMachine.new("idle", {
      stateSelector = function(entity, dt)
          return Warhog.selectState(entity, dt)
      end
  })

    stateMachine:addState("idle", Idle.new())
    stateMachine:addState("wandering", Wandering.new())
    stateMachine:addState("chasing", Chasing.new())
    stateMachine:addState("attacking", Attacking.new())
    stateMachine:addState("dying", Dying.new())

    warhog:addComponent("Position", position)
    warhog:addComponent("Movement", movement)
    warhog:addComponent("SpriteRenderer", spriteRenderer)
    warhog:addComponent("PathfindingCollision", pathfindingCollision)
    warhog:addComponent("PhysicsCollision", physicsCollision)
    warhog:addComponent("Pathfinding", pathfinding)
    warhog:addComponent("StateMachine", stateMachine)
    warhog:addComponent("Animator", animator)
    warhog:addComponent("Health", health)
    warhog:addComponent("HealthBar", healthBar)
    warhog:addComponent("Attack", attack)
    warhog:addComponent("DropTable", dropTable)
    warhog:addComponent("GroundShadow", groundShadow)

    if world then
        world:addEntity(warhog)
    end

    return warhog
end

---Update the warhog's current target
---@param entity Entity The warhog entity
function Warhog.updateTarget(entity)
    local EntityUtils = require("src.utils.entities")
    local player = EntityUtils.findPlayer(entity._world)
    local reactor = EntityUtils.findReactor(entity._world)

    local warhogPos = entity:getComponent("Position")
    if not warhogPos then
        entity.target = nil
        return
    end

    local chaseRange = WarhogConfig.CHASE_RANGE * GameConstants.TILE_SIZE
    local pathfindingCollision = entity:getComponent("PathfindingCollision")

    -- Calculate distances and check line of sight for both targets
    local playerDistance = math.huge
    local reactorDistance = math.huge
    local playerHasLOS = false
    local reactorHasLOS = false

    if player and not player.isDead then
        local px, py = EntityUtils.getClosestPointOnTarget(warhogPos.x, warhogPos.y, player)
        local dx = px - warhogPos.x
        local dy = py - warhogPos.y
        playerDistance = math.sqrt(dx*dx + dy*dy)
        playerHasLOS = not pathfindingCollision or pathfindingCollision:hasLineOfSightTo(px, py, nil)
    end

    if reactor and not reactor.isDead then
        local rx, ry = EntityUtils.getClosestPointOnTarget(warhogPos.x, warhogPos.y, reactor)
        local dx = rx - warhogPos.x
        local dy = ry - warhogPos.y
        reactorDistance = math.sqrt(dx*dx + dy*dy)
        -- Reactor doesn't need line of sight check (it's a static structure)
        reactorHasLOS = true
    end

    -- Choose target based on distance and line of sight
    -- Priority: closest target within chase range with line of sight
    local chosenTarget = nil
    local chosenDistance = math.huge

    -- Check player first (higher priority if both are valid)
    if player and playerDistance <= chaseRange and playerHasLOS and playerDistance < chosenDistance then
        chosenTarget = player
        chosenDistance = playerDistance
    end

    -- Check reactor (lower priority but still valid)
    if reactor and reactorDistance <= chaseRange and reactorHasLOS and reactorDistance < chosenDistance then
        chosenTarget = reactor
        chosenDistance = reactorDistance
    end

    entity.target = chosenTarget

end

---Select the appropriate state based on current conditions
---@param entity Entity The warhog entity
---@param dt number Delta time
---@return string The desired state name
function Warhog.selectState(entity, dt)
    local EntityUtils = require("src.utils.entities")
    local stateMachine = entity:getComponent("StateMachine")
    local health = entity:getComponent("Health")
    local currentState = stateMachine:getCurrentState()

    -- Priority 1: Check if dead
    if health and health.current <= 0 then
        return "dying"
    end

    -- Priority 2: Update target and check for detection
    Warhog.updateTarget(entity)
    local target = entity.target
    if target then

        -- Use the same distance calculation as updateTarget for consistency
        local position = entity:getComponent("Position")
        local pathfindingCollision = entity:getComponent("PathfindingCollision")

        local sx, sy = position.x, position.y
        if pathfindingCollision and pathfindingCollision:hasCollider() then
            sx, sy = pathfindingCollision:getCenterPosition()
        end

        local tx, ty = EntityUtils.getClosestPointOnTarget(sx, sy, target)
        local dx = tx - sx
        local dy = ty - sy
        local dist = math.sqrt(dx*dx + dy*dy)

        local attackRange = WarhogConfig.ATTACK_RANGE_TILES * GameConstants.TILE_SIZE

        -- Priority: attacking > chasing
        if dist <= attackRange then
            return "attacking"
        else
            return "chasing"
        end
    end

    -- Priority 3: Default behavior (idle/wandering) when no target
    -- If currently attacking or chasing but no target, transition to idle
    if currentState == "attacking" or currentState == "chasing" then
        return "idle"
    end

    -- Handle idle/wandering transitions
    if currentState == "idle" then
        -- Check if idle time has expired
        local idleTime = stateMachine:getStateData("idleTime") or 0
        local targetIdleTime = stateMachine:getStateData("targetIdleTime") or 2
        if idleTime >= targetIdleTime then
            return "wandering"
        end
    elseif currentState == "wandering" then
        -- Check if wander path is complete
        local pathfinding = entity:getComponent("Pathfinding")
        if pathfinding and pathfinding:isPathComplete() then
            return "idle"
        end
    end

    -- Default: stay in current state if no higher priority state is needed
    return currentState
end

return Warhog

