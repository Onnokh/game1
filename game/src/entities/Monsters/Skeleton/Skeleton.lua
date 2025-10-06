local Entity = require("src.core.Entity")
local Position = require("src.components.Position")
local Movement = require("src.components.Movement")
local SpriteRenderer = require("src.components.SpriteRenderer")
local PathfindingCollision = require("src.components.PathfindingCollision")
local PhysicsCollision = require("src.components.PhysicsCollision")
local StateMachine = require("src.components.StateMachine")
local Pathfinding = require("src.components.Pathfinding")
local GameConstants = require("src.constants")
local SkeletonConfig = require("src.entities.Monsters.Skeleton.SkeletonConfig")
local Attack = require("src.components.Attack")
local Health = require("src.components.Health")
local HealthBar = require("src.components.HealthBar")
local DropTable = require("src.components.DropTable")
local DepthSorting = require("src.utils.depthSorting")

local Idle = require("src.entities.Monsters.Skeleton.states.Idle")
local Wandering = require("src.entities.Monsters.Skeleton.states.Wandering")
local Chasing = require("src.entities.Monsters.Skeleton.states.Chasing")
local Attacking = require("src.entities.Monsters.Skeleton.states.Attacking")
local Dying = require("src.entities.Monsters.Skeleton.states.Dying")
local Animator = require("src.components.Animator")

---@class Skeleton
local Skeleton = {}

---Create a new skeleton enemy entity
---@param x number X position
---@param y number Y position
---@param world World The ECS world to add the skeleton to
---@param physicsWorld table|nil The physics world for collision
---@return Entity The created skeleton entity
function Skeleton.create(x, y, world, physicsWorld)

    -- Create the skeleton entity
    local skeleton = Entity.new()
    skeleton:addTag("Skeleton")
    skeleton.target = nil -- Current target (player or reactor)

    -- Create components
    local position = Position.new(x, y, DepthSorting.getLayerZ("GROUND")) -- Skeleton at ground level
    local movement = Movement.new(GameConstants.PLAYER_SPEED, 2000, 1) -- maxSpeed, acceleration, friction

    local spriteRenderer = SpriteRenderer.new(nil, SkeletonConfig.SPRITE_WIDTH, SkeletonConfig.SPRITE_HEIGHT)

    -- PathfindingCollision component (for pathfinding and physics collision)
    -- Collider centered at bottom: width 12, height 8, offsetX centers horizontally, offsetY positions at bottom
    local colliderWidth, colliderHeight = SkeletonConfig.COLLIDER_WIDTH, SkeletonConfig.COLLIDER_HEIGHT
    local colliderShape = SkeletonConfig.COLLIDER_SHAPE
    local offsetX = (spriteRenderer.width - colliderWidth) / 2
    local offsetY = spriteRenderer.height - colliderHeight - 8
    local pathfindingCollision = PathfindingCollision.new(colliderWidth, colliderHeight, "dynamic", offsetX, offsetY, colliderShape)
    pathfindingCollision.restitution = SkeletonConfig.COLLIDER_RESTITUTION
    pathfindingCollision.friction = SkeletonConfig.COLLIDER_FRICTION
    pathfindingCollision.linearDamping = SkeletonConfig.COLLIDER_DAMPING

    -- PhysicsCollision component (for physics interactions only) - use sprite size
    local physicsCollision = PhysicsCollision.new(SkeletonConfig.DRAW_WIDTH, SkeletonConfig.DRAW_HEIGHT, "dynamic", spriteRenderer.width / 2 - SkeletonConfig.DRAW_WIDTH / 2, spriteRenderer.height / 2 - SkeletonConfig.DRAW_HEIGHT / 2, "rectangle")
    physicsCollision.restitution = SkeletonConfig.COLLIDER_RESTITUTION
    physicsCollision.friction = SkeletonConfig.COLLIDER_FRICTION
    physicsCollision.linearDamping = SkeletonConfig.COLLIDER_DAMPING

    -- Create colliders if physics world is available
    if physicsWorld then
        pathfindingCollision:createCollider(physicsWorld, x, y)
        physicsCollision:createCollider(physicsWorld, x, y)
    end

    -- Create pathfinding component
    local pathfinding = Pathfinding.new(x, y, SkeletonConfig.WANDER_RADIUS) -- 8 tile wander radius

    local animator = Animator.new("skeleton", SkeletonConfig.IDLE_ANIMATION.frames, SkeletonConfig.IDLE_ANIMATION.fps, SkeletonConfig.IDLE_ANIMATION.loop)

    -- Create health component
    local health = Health.new(SkeletonConfig.MAX_HEALTH, SkeletonConfig.HEALTH)
    local attack = Attack.new(SkeletonConfig.ATTACK_DAMAGE, (SkeletonConfig.ATTACK_RANGE_TILES or 1.0) * GameConstants.TILE_SIZE, SkeletonConfig.ATTACK_COOLDOWN, "melee", SkeletonConfig.ATTACK_KNOCKBACK)

    -- Create health bar component (16x2 pixels, positioned above skeleton)
    local healthBar = HealthBar.new(16, 2, 0)

    -- Create drop table component for loot drops (0-3 coins)
    local dropTable = DropTable.new()
    dropTable:addDrop("coin", 1, 3, 1.0) -- 100% chance to drop 1-3 coins

     -- Create state machine with priority-based state selection
     local stateMachine = StateMachine.new("idle", {
      stateSelector = function(entity, dt)
          return Skeleton.selectState(entity, dt)
      end
  })

    stateMachine:addState("idle", Idle.new())
    stateMachine:addState("wandering", Wandering.new())
    stateMachine:addState("chasing", Chasing.new())
    stateMachine:addState("attacking", Attacking.new())
    stateMachine:addState("dying", Dying.new())

    skeleton:addComponent("Position", position)
    skeleton:addComponent("Movement", movement)
    skeleton:addComponent("SpriteRenderer", spriteRenderer)
    skeleton:addComponent("PathfindingCollision", pathfindingCollision)
    skeleton:addComponent("PhysicsCollision", physicsCollision)
    skeleton:addComponent("Pathfinding", pathfinding)
    skeleton:addComponent("StateMachine", stateMachine)
    skeleton:addComponent("Animator", animator)
    skeleton:addComponent("Health", health)
    skeleton:addComponent("HealthBar", healthBar)
    skeleton:addComponent("Attack", attack)
    skeleton:addComponent("DropTable", dropTable)

    if world then
        world:addEntity(skeleton)
    end

    return skeleton
end

---Update the skeleton's current target
---@param entity Entity The skeleton entity
function Skeleton.updateTarget(entity)
    local EntityUtils = require("src.utils.entities")
    local player = EntityUtils.findPlayer(entity._world)
    local reactor = EntityUtils.findReactor(entity._world)

    local skeletonPos = entity:getComponent("Position")
    if not skeletonPos then
        entity.target = nil
        return
    end

    local chaseRange = SkeletonConfig.CHASE_RANGE * GameConstants.TILE_SIZE
    local pathfindingCollision = entity:getComponent("PathfindingCollision")

    -- Calculate distances and check line of sight for both targets
    local playerDistance = math.huge
    local reactorDistance = math.huge
    local playerHasLOS = false
    local reactorHasLOS = false

    if player and not player.isDead then
        local px, py = EntityUtils.getClosestPointOnTarget(skeletonPos.x, skeletonPos.y, player)
        local dx = px - skeletonPos.x
        local dy = py - skeletonPos.y
        playerDistance = math.sqrt(dx*dx + dy*dy)
        playerHasLOS = not pathfindingCollision or pathfindingCollision:hasLineOfSightTo(px, py, nil)
    end

    if reactor and not reactor.isDead then
        local rx, ry = EntityUtils.getClosestPointOnTarget(skeletonPos.x, skeletonPos.y, reactor)
        local dx = rx - skeletonPos.x
        local dy = ry - skeletonPos.y
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
---@param entity Entity The skeleton entity
---@param dt number Delta time
---@return string The desired state name
function Skeleton.selectState(entity, dt)
    local EntityUtils = require("src.utils.entities")
    local stateMachine = entity:getComponent("StateMachine")
    local health = entity:getComponent("Health")
    local currentState = stateMachine:getCurrentState()

    -- Priority 1: Check if dead
    if health and health.current <= 0 then
        return "dying"
    end

    -- Priority 2: Update target and check for detection
    Skeleton.updateTarget(entity)
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

        local attackRange = SkeletonConfig.ATTACK_RANGE_TILES * GameConstants.TILE_SIZE

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

return Skeleton
