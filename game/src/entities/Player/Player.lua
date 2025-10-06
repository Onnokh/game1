local Entity = require("src.core.Entity")
local Position = require("src.components.Position")
local Movement = require("src.components.Movement")
local SpriteRenderer = require("src.components.SpriteRenderer")
local PathfindingCollision = require("src.components.PathfindingCollision")
local PhysicsCollision = require("src.components.PhysicsCollision")
local StateMachine = require("src.components.StateMachine")
local Attack = require("src.components.Attack")
local Health = require("src.components.Health")
local Oxygen = require("src.components.Oxygen")
local ParticleSystem = require("src.components.ParticleSystem")
local GroundShadow = require("src.components.GroundShadow")
local GameConstants = require("src.constants")
local PlayerConfig = require("src.entities.Player.PlayerConfig")
local DepthSorting = require("src.utils.depthSorting")

local Idle = require("src.entities.Player.states.Idle")
local Moving = require("src.entities.Player.states.Moving")
local Running = require("src.entities.Player.states.Running")
local Dash = require("src.entities.Player.states.Dash")

---@class Player
local Player = {}

---Create a new player entity
---@param x number X position
---@param y number Y position
---@param world World The ECS world to add the player to
---@param physicsWorld table|nil The physics world for collision
---@return Entity The created player entity
function Player.create(x, y, world, physicsWorld)

    -- Create the player entity
    local player = Entity.new()

    ---@class PlayerEntity : Entity
    local playerEntity = player

    -- Tag for easy querying/filters
    playerEntity:addTag("Player")

    -- Create components
    local position = Position.new(x, y, DepthSorting.getLayerZ("PLAYER")) -- Player layer
    local movement = Movement.new(GameConstants.PLAYER_SPEED, 3000, 1) -- maxSpeed, acceleration, friction

    local spriteRenderer = SpriteRenderer.new(nil, PlayerConfig.SPRITE_WIDTH, PlayerConfig.SPRITE_HEIGHT)
    spriteRenderer.facingMouse = true -- Enable mouse-facing

    -- PathfindingCollision component (for pathfinding and physics collision)
    -- Collider centered at bottom: width 12, height 8, offsetX centers horizontally, offsetY positions at bottom
    local colliderWidth, colliderHeight = PlayerConfig.COLLIDER_WIDTH, PlayerConfig.COLLIDER_HEIGHT
    local colliderShape = PlayerConfig.COLLIDER_SHAPE
    local offsetX = (spriteRenderer.width - colliderWidth) / 2
    local offsetY = spriteRenderer.height - colliderHeight
    local pathfindingCollision = PathfindingCollision.new(colliderWidth, colliderHeight, "dynamic", offsetX, offsetY, colliderShape)
    pathfindingCollision.restitution = PlayerConfig.COLLIDER_RESTITUTION
    pathfindingCollision.friction = PlayerConfig.COLLIDER_FRICTION
    pathfindingCollision.linearDamping = PlayerConfig.COLLIDER_DAMPING

    -- PhysicsCollision component (for physics interactions only) - use sprite size, force rectangle shape
    local physicsCollision = PhysicsCollision.new(12, 16, "dynamic", 6, 6, "rectangle")
    physicsCollision.restitution = PlayerConfig.COLLIDER_RESTITUTION
    physicsCollision.friction = PlayerConfig.COLLIDER_FRICTION
    physicsCollision.linearDamping = PlayerConfig.COLLIDER_DAMPING

    -- Create colliders if physics world is available
    if physicsWorld then
        pathfindingCollision:createCollider(physicsWorld, x, y)
        physicsCollision:createCollider(physicsWorld, x, y)
    end

    -- Create state machine first
    local stateMachine = StateMachine.new("idle")

    -- Set up the state selector function (automatically enables auto transitions)
    stateMachine:setStateSelector(function(entity, dt)
        local GameState = require("src.core.GameState")
        if not GameState or not GameState.input then return "idle" end

        -- Priority-based state system (like modern engines!)
        local InputHelpers = require("src.utils.input")

        -- Check dash cooldown before allowing dash
        local dashCooldown = stateMachine:getGlobalData("dashCooldown") or 0
        local canDash = dashCooldown <= 0

        if InputHelpers.hasMovementInput(GameState.input) and InputHelpers.isActionInput(GameState.input) and canDash then
            return "dash"      -- Highest priority - dash when space is pressed and cooldown is ready
        elseif InputHelpers.hasMovementInput(GameState.input) and InputHelpers.isRunningInput(GameState.input) then
            return "running"   -- Second priority - running when shift + movement
        elseif InputHelpers.hasMovementInput(GameState.input) then
            return "moving"    -- Third priority - moving when movement input
        else
            return "idle"      -- Lowest priority - idle when no input
        end
    end)

    stateMachine:addState("idle", Idle.new())
    stateMachine:addState("moving", Moving.new())
    stateMachine:addState("running", Running.new())
    stateMachine:addState("dash", Dash.new())

    -- Create attack component
    local attack = Attack.new(32, 15, 0.5, "melee", 6) -- damage, range, cooldown, type, knockback

    -- Create health component
    local health = Health.new(100) -- 100 max health

    -- Create oxygen component
    local oxygen = Oxygen.new(100) -- 100 max oxygen

    -- Create particle system for walking effects
    local particleSystem = ParticleSystem.new(50, 0, 0) -- maxParticles, gravity, wind
    local groundShadow = GroundShadow.new({ alpha = .5, widthFactor = 0.8, heightFactor = 0.18, offsetY = 0 })

    -- Add all components to the player
    playerEntity:addComponent("Position", position)
    playerEntity:addComponent("Movement", movement)
    playerEntity:addComponent("SpriteRenderer", spriteRenderer)
    playerEntity:addComponent("PathfindingCollision", pathfindingCollision)
    playerEntity:addComponent("PhysicsCollision", physicsCollision)
    playerEntity:addComponent("StateMachine", stateMachine)
    playerEntity:addComponent("Attack", attack)
    playerEntity:addComponent("Health", health)
    playerEntity:addComponent("Oxygen", oxygen)
    playerEntity:addComponent("ParticleSystem", particleSystem)
    playerEntity:addComponent("GroundShadow", groundShadow)

    if world then
        world:addEntity(playerEntity)
    end

    return playerEntity
end

return Player
