---@class Player
local Player = {}

---Create a new player entity
---@param x number X position
---@param y number Y position
---@param world World The ECS world to add the player to
---@param physicsWorld table|nil The physics world for collision
---@param gameState table|nil The game state for input access
---@return Entity The created player entity
function Player.create(x, y, world, physicsWorld, gameState)
    local Entity = require("src.core.Entity")
    local Position = require("src.components.Position")
    local Movement = require("src.components.Movement")
    local SpriteRenderer = require("src.components.SpriteRenderer")
    local Collision = require("src.components.Collision")
    local StateMachine = require("src.components.StateMachine")
    local GameConstants = require("src.constants")

    -- Create the player entity
    local player = Entity.new()

    -- Create components
    local position = Position.new(x, y, 0)
    local movement = Movement.new(GameConstants.PLAYER_SPEED, 3000, 1) -- maxSpeed, acceleration, friction

    local spriteRenderer = SpriteRenderer.new(nil, 24, 24) -- width, height (24x24 sprite)
    spriteRenderer.facingMouse = true -- Enable mouse-facing


    -- Collision component
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

    -- State machine setup
    local stateMachine = StateMachine.new("idle")
    local Idle = require("src.entities.Player.states.Idle")
    local Moving = require("src.entities.Player.states.Moving")

    stateMachine:addState("idle", Idle.new())
    stateMachine:addState("moving", Moving.new())

    -- State transitions
    stateMachine:addTransition("idle", "moving", function(self, entity, dt)
        local GameState = require("src.core.State")
        if not GameState or not GameState.input then return false end

        local hasInput = GameState.input.left or GameState.input.right or
                        GameState.input.up or GameState.input.down

        return hasInput
    end)

    stateMachine:addTransition("moving", "idle", function(self, entity, dt)
        local GameState = require("src.core.State")
        if not GameState or not GameState.input then return false end

        local hasInput = GameState.input.left or GameState.input.right or
                        GameState.input.up or GameState.input.down

        return not hasInput
    end)

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
