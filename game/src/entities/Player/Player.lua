local Entity = require("src.core.Entity")
local Position = require("src.components.Position")
local Movement = require("src.components.Movement")
local SpriteRenderer = require("src.components.SpriteRenderer")
local PathfindingCollision = require("src.components.PathfindingCollision")
local PhysicsCollision = require("src.components.PhysicsCollision")
local StateMachine = require("src.components.StateMachine")
local Attack = require("src.components.Attack")
local Weapon = require("src.components.Weapon")
local Health = require("src.components.Health")
local Oxygen = require("src.components.Oxygen")
local ParticleSystem = require("src.components.ParticleSystem")
local GroundShadow = require("src.components.GroundShadow")
local Animator = require("src.components.Animator")
local Inventory = require("src.components.Inventory")
local FootprintsEmitter = require("src.components.FootprintsEmitter")
local DashCharges = require("src.components.DashCharges")
local UpgradeTracker = require("src.components.UpgradeTracker")
local Modifier = require("src.components.Modifier")
local MinimapIcon = require("src.components.MinimapIcon")
local GameConstants = require("src.constants")
local PlayerConfig = require("src.entities.Player.PlayerConfig")
local DepthSorting = require("src.utils.depthSorting")
local weaponDefinitions = require("src.definitions.weapons")
local sprites = require("src.utils.sprites")

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
    spriteRenderer:setOutline({r = 0.0, g = 0.0, b = 0.0}) -- White outline

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
    local physicsCollision = PhysicsCollision.new(12, 26, "dynamic", 10, 6, "rectangle")
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

        -- Check dash charges before allowing dash
        local dashCharges = entity:getComponent("DashCharges")
        local canDash = dashCharges and dashCharges:canDash() or false

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

    -- Create weapon component with weapon inventory
    local weaponInventory = weaponDefinitions.getAllWeapons()
    local weapon = Weapon.new("ranged", weaponInventory)

    -- Create attack component (tracks attack execution state)
    -- Actual weapon stats come from Weapon component
    local attack = Attack.new()

    -- Create health component
    local health = Health.new(100) -- 100 max health

    -- Create oxygen component
    local oxygen = Oxygen.new(100) -- 100 max oxygen

    -- Create particle system for walking effects
    local particleSystem = ParticleSystem.new(50, 0, 0) -- maxParticles, gravity, wind
    local groundShadow = GroundShadow.new({ alpha = .5, widthFactor = 1.2, heightFactor = 0.4, offsetY = 0 })

    -- Create animator component with idle animation
    local animator = Animator.new(PlayerConfig.IDLE_ANIMATION)

    -- Create inventory component
    local inventory = Inventory.new()

    -- Create dash charges component (start with 1 charge, can upgrade to 3)
    local dashCharges = DashCharges.new(1, PlayerConfig.DASH_CHARGE_REGEN_TIME)

    -- Create upgrade tracker and modifier components
    local upgradeTracker = UpgradeTracker.new()
    local modifier = Modifier.new()

    -- Add all components to the player
    playerEntity:addComponent("Position", position)
    playerEntity:addComponent("Movement", movement)
    playerEntity:addComponent("SpriteRenderer", spriteRenderer)
    playerEntity:addComponent("PathfindingCollision", pathfindingCollision)
    playerEntity:addComponent("PhysicsCollision", physicsCollision)
    playerEntity:addComponent("StateMachine", stateMachine)
    playerEntity:addComponent("Animator", animator)
    playerEntity:addComponent("Weapon", weapon)
    playerEntity:addComponent("Attack", attack)
    playerEntity:addComponent("Health", health)
    playerEntity:addComponent("Oxygen", oxygen)
    playerEntity:addComponent("ParticleSystem", particleSystem)
    playerEntity:addComponent("GroundShadow", groundShadow)
    playerEntity:addComponent("Inventory", inventory)
    playerEntity:addComponent("DashCharges", dashCharges)
    playerEntity:addComponent("UpgradeTracker", upgradeTracker)
    playerEntity:addComponent("Modifier", modifier)
    playerEntity:addComponent("FootprintsEmitter", FootprintsEmitter.new({
        spacing = 15,
        lifetime = 5,
        baseAlpha = 0.45,
        limbs = {
            { lateral = -3, phase = 0.0 },
            { lateral =  3, phase = 0.5 }
        },
        maxCount = 300,
        pausedByStates = { "dash" }
    }))
    -- Add minimap icon with the player icon
    playerEntity:addComponent("MinimapIcon", MinimapIcon.new("player", nil, 6, sprites.getImage("minimapPlayer")))

    if world then
        world:addEntity(playerEntity)
    end

    return playerEntity
end

return Player
