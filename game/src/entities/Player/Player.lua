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
    local position = Position.new(x, y, 0)
    local movement = Movement.new(GameConstants.PLAYER_SPEED, 3000, 1) -- maxSpeed, acceleration, friction

    local spriteRenderer = SpriteRenderer.new(nil, PlayerConfig.SPRITE_WIDTH, PlayerConfig.SPRITE_HEIGHT)
    spriteRenderer.facingMouse = true -- Enable mouse-facing


    -- Collision component
    -- Collider centered at bottom: width 12, height 8, offsetX centers horizontally, offsetY positions at bottom
    local colliderWidth, colliderHeight = PlayerConfig.COLLIDER_WIDTH, PlayerConfig.COLLIDER_HEIGHT
    local offsetX = (spriteRenderer.width - colliderWidth) / 2
    local offsetY = spriteRenderer.height - colliderHeight
    local collision = Collision.new(colliderWidth, colliderHeight, "dynamic", offsetX, offsetY)
    collision.restitution = PlayerConfig.COLLIDER_RESTITUTION
    collision.friction = PlayerConfig.COLLIDER_FRICTION
    collision.linearDamping = PlayerConfig.COLLIDER_DAMPING

    -- Create collider if physics world is available
    if physicsWorld then
        collision:createCollider(physicsWorld, x, y)
    end

    -- State machine setup
    local stateMachine = StateMachine.new("idle")
    local Idle = require("src.entities.Player.states.Idle")
    local Moving = require("src.entities.Player.states.Moving")
    local Running = require("src.entities.Player.states.Running")
    local Dash = require("src.entities.Player.states.Dash")

    stateMachine:addState("idle", Idle.new())
    stateMachine:addState("moving", Moving.new())
    stateMachine:addState("running", Running.new())
    stateMachine:addState("dash", Dash.new())

    -- Priority-based state system (like modern engines!)
    local InputHelpers = require("src.utils.input")

    local function getPlayerState(input)
        -- Check dash cooldown before allowing dash
        local dashCooldown = stateMachine:getGlobalData("dashCooldown") or 0
        local canDash = dashCooldown <= 0

        if InputHelpers.hasMovementInput(input) and InputHelpers.isActionInput(input) and canDash then
            return "dash"      -- Highest priority - dash when space is pressed and cooldown is ready
        elseif InputHelpers.hasMovementInput(input) and InputHelpers.isRunningInput(input) then
            return "running"   -- Second priority - running when shift + movement
        elseif InputHelpers.hasMovementInput(input) then
            return "moving"    -- Third priority - moving when movement input
        else
            return "idle"      -- Lowest priority - idle when no input
        end
    end

    -- Priority-based transitions - much cleaner!
    -- Each state checks if it should transition to a higher priority state
    stateMachine:addTransition("idle", "moving", function(self, entity, dt)
        local GameState = require("src.core.GameState")
        if not GameState or not GameState.input then return false end
        return getPlayerState(GameState.input) == "moving"
    end)

    stateMachine:addTransition("idle", "running", function(self, entity, dt)
        local GameState = require("src.core.GameState")
        if not GameState or not GameState.input then return false end
        return getPlayerState(GameState.input) == "running"
    end)

    stateMachine:addTransition("moving", "running", function(self, entity, dt)
        local GameState = require("src.core.GameState")
        if not GameState or not GameState.input then return false end
        return getPlayerState(GameState.input) == "running"
    end)

    stateMachine:addTransition("moving", "idle", function(self, entity, dt)
        local GameState = require("src.core.GameState")
        if not GameState or not GameState.input then return false end
        return getPlayerState(GameState.input) == "idle"
    end)

    stateMachine:addTransition("running", "moving", function(self, entity, dt)
        local GameState = require("src.core.GameState")
        if not GameState or not GameState.input then return false end
        return getPlayerState(GameState.input) == "moving"
    end)

    stateMachine:addTransition("running", "idle", function(self, entity, dt)
        local GameState = require("src.core.GameState")
        if not GameState or not GameState.input then return false end
        return getPlayerState(GameState.input) == "idle"
    end)

    -- Dash transitions - dash has highest priority
    stateMachine:addTransition("idle", "dash", function(self, entity, dt)
        local GameState = require("src.core.GameState")
        if not GameState or not GameState.input then return false end
        return getPlayerState(GameState.input) == "dash"
    end)

    stateMachine:addTransition("moving", "dash", function(self, entity, dt)
        local GameState = require("src.core.GameState")
        if not GameState or not GameState.input then return false end
        return getPlayerState(GameState.input) == "dash"
    end)

    stateMachine:addTransition("running", "dash", function(self, entity, dt)
        local GameState = require("src.core.GameState")
        if not GameState or not GameState.input then return false end
        return getPlayerState(GameState.input) == "dash"
    end)

    stateMachine:addTransition("dash", "idle", function(self, entity, dt)
        local GameState = require("src.core.GameState")
        if not GameState or not GameState.input then return false end
        return getPlayerState(GameState.input) == "idle"
    end)

    stateMachine:addTransition("dash", "moving", function(self, entity, dt)
        local GameState = require("src.core.GameState")
        if not GameState or not GameState.input then return false end
        return getPlayerState(GameState.input) == "moving"
    end)

    stateMachine:addTransition("dash", "running", function(self, entity, dt)
        local GameState = require("src.core.GameState")
        if not GameState or not GameState.input then return false end
        return getPlayerState(GameState.input) == "running"
    end)

    -- Add cooldown update logic to state machine
    local originalUpdate = stateMachine.update
    stateMachine.update = function(self, dt, entity)
        -- Update cooldowns
        local dashCooldown = self:getGlobalData("dashCooldown") or 0
        if dashCooldown > 0 then
            dashCooldown = dashCooldown - dt
            self:setGlobalData("dashCooldown", dashCooldown)
        end

        -- Call original update
        originalUpdate(self, dt, entity)
    end

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
