---@class Moving
---Moving state for player
local Moving = {}

function Moving.new()
    return {
        onEnter = function(stateMachine, entity)
            stateMachine:setStateData("walkTime", 0)

            -- Create and set walking animation when entering state
            if entity then
                local Animator = require("src.components.Animator")
                local animator = entity:getComponent("Animator")

                if not animator then
                    -- Create animator if it doesn't exist
                    animator = Animator.new("character", {9, 10, 11, 12}, 8, true)
                    entity:addComponent("Animator", animator)
                else
                    -- Set walking animation: frames 9-12, 8 fps
                    animator:setAnimation({9, 10, 11, 12}, 8, true)
                end
            end
        end,

        onUpdate = function(stateMachine, entity, dt)
            local walkTime = stateMachine:getStateData("walkTime") or 0
            stateMachine:setStateData("walkTime", walkTime + dt)

            -- Handle movement input
            local movement = entity:getComponent("Movement")

            -- Access gameState from the global state
            local GameState = require("src.core.State")
            if GameState and GameState.input and movement then
                local velocityX, velocityY = 0, 0
                if GameState.input.left then velocityX = -movement.maxSpeed end
                if GameState.input.right then velocityX = movement.maxSpeed end
                if GameState.input.up then velocityY = -movement.maxSpeed end
                if GameState.input.down then velocityY = movement.maxSpeed end
                movement:setVelocity(velocityX, velocityY)
            end
        end
    }
end

return Moving
