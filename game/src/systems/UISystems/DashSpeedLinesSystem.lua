local System = require("src.core.System")
local ShaderManager = require("src.core.managers.ShaderManager")
local EntityUtils = require("src.utils.entities")

---@class DashSpeedLinesSystem : System
---Renders radial speed lines effect when player is dashing
local DashSpeedLinesSystem = System:extend("DashSpeedLinesSystem", {})

---Create a new DashSpeedLinesSystem
---@param ecsWorld World
---@return DashSpeedLinesSystem
function DashSpeedLinesSystem.new(ecsWorld)
    ---@class DashSpeedLinesSystem
    local self = System.new()
    setmetatable(self, DashSpeedLinesSystem)
    self.ecsWorld = ecsWorld
    self.isWorldSpace = false -- Screen space rendering
    self.opacity = 0.0 -- 0 = no effect, 1 = full effect
    self.targetOpacity = 0.0 -- Target opacity to fade to
    self.fadeSpeed = 4.0 -- Speed of fade transition (units per second)
    return self
end

---Check if player is currently dashing
---@return boolean True if player is dashing
function DashSpeedLinesSystem:isPlayerDashing()
    -- Find the player entity
    local player = EntityUtils.findPlayer(self.ecsWorld)
    if not player then
        return false
    end

    local stateMachine = player:getComponent("StateMachine")
    if not stateMachine then
        return false
    end

    return stateMachine:getCurrentState() == "dash"
end

---Update the speed lines based on dash status
---@param dt number Delta time
function DashSpeedLinesSystem:update(dt)
    -- Show speed lines when player is dashing
    local isDashing = self:isPlayerDashing()
    self.targetOpacity = isDashing and 1.0 or 0.0

    -- Smoothly interpolate current opacity towards target
    if self.opacity < self.targetOpacity then
        -- Fade in
        self.opacity = math.min(self.opacity + self.fadeSpeed * dt, self.targetOpacity)
    elseif self.opacity > self.targetOpacity then
        -- Fade out
        self.opacity = math.max(self.opacity - self.fadeSpeed * dt, self.targetOpacity)
    end
end

---Draw the speed lines effect using shader
function DashSpeedLinesSystem:draw()
    -- Only draw if there's some visible opacity
    if self.opacity <= 0.0 then
        return
    end

    local shader = ShaderManager.getShader("speed_lines")
    if not shader then
        return
    end

    -- Get screen dimensions
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()

    -- Set shader uniforms
    shader:send("line_color", {1.0, 1.0, 1.0, 1.0}) -- Pure white
    shader:send("line_count", 0.6)
    shader:send("mask_size", 0.50)
    shader:send("mask_edge", 0.85)
    shader:send("animation_speed", 6.0)
    shader:send("time", love.timer.getTime())
    shader:send("resolution", {screenWidth, screenHeight})
    shader:send("opacity", self.opacity)

    love.graphics.push()
    love.graphics.origin()

    -- Use alpha blend mode
    love.graphics.setBlendMode("alpha", "alphamultiply")
    love.graphics.setShader(shader)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)
    love.graphics.setShader()
    love.graphics.setBlendMode("alpha")

    love.graphics.pop()
end

return DashSpeedLinesSystem
