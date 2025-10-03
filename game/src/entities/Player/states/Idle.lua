---@class Idle
---Idle state for player
local Idle = {}

function Idle.new()
    return {
        onEnter = function(stateMachine, entity)
            stateMachine:setStateData("idleTime", 0)

            -- Create and set idle animation when entering state
            if entity then
                local Animator = require("src.components.Animator")
                local animator = entity:getComponent("Animator")

                if not animator then
                    -- Create animator if it doesn't exist
                    animator = Animator.new("character", {1, 2}, 4, true)
                    entity:addComponent("Animator", animator)
                else
                    -- Set idle animation: frames 1-2, 4 fps
                    animator:setAnimation({1, 2}, 4, true)
                end
            end
        end,

        onUpdate = function(stateMachine, entity, dt)
            local idleTime = stateMachine:getStateData("idleTime") or 0
            stateMachine:setStateData("idleTime", idleTime + dt)
        end
    }
end

return Idle
