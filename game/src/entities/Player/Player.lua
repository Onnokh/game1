---@class Player
local Player = {}

---Create a new player entity
---@param x number X position
---@param y number Y position
---@param world World The ECS world to add the player to
---@param physicsWorld table|nil The physics world for collision
---@return Entity The created player entity
function Player.create(x, y, world, physicsWorld)
    local Entity = require("src.core.Entity")
    local Position = require("src.components.Position")
    local Movement = require("src.components.Movement")
    local SpriteRenderer = require("src.components.SpriteRenderer")
    local Collision = require("src.components.Collision")
    local StateMachine = require("src.components.StateMachine")
    local GameConstants = require("src.constants")
    local PlayerConfig = require("src.entities.Player.PlayerConfig")

    -- Create the player entity
    local player = Entity.new()

    -- Create components
    local position = Position.new(x, y, 1) -- Player in front of monsters
    local movement = Movement.new(GameConstants.PLAYER_SPEED, 3000, 1) -- maxSpeed, acceleration, friction

    local spriteRenderer = SpriteRenderer.new(nil, PlayerConfig.SPRITE_WIDTH, PlayerConfig.SPRITE_HEIGHT)
    spriteRenderer.facingMouse = true -- Enable mouse-facing


    -- Collision component
    -- Collider centered at bottom: width 12, height 8, offsetX centers horizontally, offsetY positions at bottom
    local colliderWidth, colliderHeight = PlayerConfig.COLLIDER_WIDTH, PlayerConfig.COLLIDER_HEIGHT
    local colliderShape = PlayerConfig.COLLIDER_SHAPE
    local offsetX = (spriteRenderer.width - colliderWidth) / 2
    local offsetY = spriteRenderer.height - colliderHeight
    local collision = Collision.new(colliderWidth, colliderHeight, "dynamic", offsetX, offsetY, colliderShape)
    collision.restitution = PlayerConfig.COLLIDER_RESTITUTION
    collision.friction = PlayerConfig.COLLIDER_FRICTION
    collision.linearDamping = PlayerConfig.COLLIDER_DAMPING

    -- Create collider if physics world is available
    if physicsWorld then
        collision:createCollider(physicsWorld, x, y)
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

    local Idle = require("src.entities.Player.states.Idle")
    local Moving = require("src.entities.Player.states.Moving")
    local Running = require("src.entities.Player.states.Running")
    local Dash = require("src.entities.Player.states.Dash")

    stateMachine:addState("idle", Idle.new())
    stateMachine:addState("moving", Moving.new())
    stateMachine:addState("running", Running.new())
    stateMachine:addState("dash", Dash.new())

    -- Add all components to the player
    player:addComponent("Position", position)
    player:addComponent("Movement", movement)
    player:addComponent("SpriteRenderer", spriteRenderer)
    player:addComponent("Collision", collision)
    player:addComponent("StateMachine", stateMachine)

    -- Add the player to the world
    if world then
        world:addEntity(player)
    end

    return player
end

return Player
