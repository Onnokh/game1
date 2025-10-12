local System = require("src.core.System")
local ShaderManager = require("src.core.managers.ShaderManager")
local EntityUtils = require("src.utils.entities")

---@class AggroVignetteSystem : System
---Renders a vignette effect when mobs are chasing or attacking the player
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
    self.vignetteOpacity = 0.0 -- 0 = no vignette, 1 = full vignette
    self.targetOpacity = 0.0 -- Target opacity to fade to
    self.fadeSpeed = 2.0 -- Speed of fade transition (units per second)
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
    -- Show vignette when player is being targeted by mobs
    local isBeingTargeted = self:isPlayerBeingTargeted()
    self.targetOpacity = isBeingTargeted and 1.0 or 0.0

    -- Smoothly interpolate current opacity towards target
    if self.vignetteOpacity < self.targetOpacity then
        -- Fade in
        self.vignetteOpacity = math.min(self.vignetteOpacity + self.fadeSpeed * dt, self.targetOpacity)
    elseif self.vignetteOpacity > self.targetOpacity then
        -- Fade out
        self.vignetteOpacity = math.max(self.vignetteOpacity - self.fadeSpeed * dt, self.targetOpacity)
    end
end

---Draw the vignette effect using shader
function AggroVignetteSystem:draw()
    -- Only draw if there's some visible opacity
    if self.vignetteOpacity <= 0.0 then
        return
    end

    local shader = ShaderManager.getShader("vignette")
    if not shader then
        return
    end

    -- Get screen dimensions
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()

    -- Set shader uniforms with current faded opacity
    shader:send("opacity", self.vignetteOpacity)
    shader:send("resolution", {screenWidth, screenHeight})
    shader:send("time", love.timer.getTime())

    love.graphics.push()
    love.graphics.origin()

    -- Use alpha blend mode for solid colors
    love.graphics.setBlendMode("alpha", "alphamultiply")
    love.graphics.setShader(shader)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)
    love.graphics.setShader()
    love.graphics.setBlendMode("alpha")

    love.graphics.pop()
end

return AggroVignetteSystem

