local System = require("src.core.System")
local PostprocessingManager = require("src.core.managers.PostprocessingManager")
local EntityUtils = require("src.utils.entities")

---@class AggroVignetteSystem : System
---Updates vignette postprocessing effect to indicate when player is being targeted
local AggroVignetteSystem = System:extend("AggroVignetteSystem", {})

---Create a new AggroVignetteSystem
---@param ecsWorld World
---@return AggroVignetteSystem
function AggroVignetteSystem.new(ecsWorld)
    ---@class AggroVignetteSystem
    local self = System.new()
    setmetatable(self, AggroVignetteSystem)
    self.ecsWorld = ecsWorld
    self.isWorldSpace = false -- Screen space rendering
    return self
end

---Check if any mobs are actively chasing or attacking the player
---@return boolean True if player is being targeted by mobs
function AggroVignetteSystem:isPlayerBeingTargeted()
    -- Find the player entity
    local player = EntityUtils.findPlayer(self.ecsWorld)
    if not player then
        return false
    end

    -- Check all entities in the world
    for _, entity in ipairs(self.ecsWorld.entities) do
        -- Skip if this is the player itself or entity is dead
        if entity ~= player and entity.active and not entity.isDead then
            local stateMachine = entity:getComponent("StateMachine")

            -- Check if entity has a state machine and is in chasing or attacking state
            if stateMachine then
                local currentState = stateMachine:getCurrentState()

                if currentState == "chasing" or currentState == "attacking" then
                    -- Check if this entity is targeting the player
                    if entity.target == player then
                        return true -- Found at least one mob targeting the player
                    end
                end
            end
        end
    end

    return false -- No mobs are actively targeting the player
end

---Update the vignette based on mob aggro status
---@param dt number Delta time
function AggroVignetteSystem:update(dt)
    local isBeingTargeted = self:isPlayerBeingTargeted()

    if isBeingTargeted then
        -- Change vignette to red when under attack
        PostprocessingManager.setEffectParameter("vignette", "color", {0.8, 0.1, 0.1, 0.5})
    else
        -- Change vignette back to black when safe
        PostprocessingManager.setEffectParameter("vignette", "color", {0.0, 0.0, 0.0, 1.0})
    end
end

return AggroVignetteSystem

