local System = require("src.core.System")
local ShaderManager = require("src.utils.ShaderManager")
local EntityUtils = require("src.utils.entities")

---@class SafezoneVignetteSystem : System
---Renders a vignette effect when player is outside the reactor safezone
local SafezoneVignetteSystem = System:extend("SafezoneVignetteSystem", {})

---Create a new SafezoneVignetteSystem
---@param ecsWorld World
---@param oxygenSystem OxygenSystem|nil Optional reference to OxygenSystem
---@return SafezoneVignetteSystem
function SafezoneVignetteSystem.new(ecsWorld, oxygenSystem)
    ---@class SafezoneVignetteSystem
    local self = System.new()
    setmetatable(self, SafezoneVignetteSystem)
    self.ecsWorld = ecsWorld
    self.oxygenSystem = oxygenSystem or nil -- Direct reference to OxygenSystem
    self.isWorldSpace = false -- Screen space rendering
    self.vignetteOpacity = 0.0 -- 0 = no vignette, 1 = full vignette
    self.targetOpacity = 0.0 -- Target opacity to fade to
    self.fadeSpeed = 2.0 -- Speed of fade transition (units per second)
    return self
end

---Update the vignette based on player position
---@param dt number Delta time
function SafezoneVignetteSystem:update(dt)
    -- Check if we have the OxygenSystem reference
    if not self.oxygenSystem then
        self.targetOpacity = 0.0
        return
    end

    -- Find the player entity
    local player = EntityUtils.findPlayer(self.ecsWorld)
    if not player then
        self.targetOpacity = 0.0
        return
    end

    local position = player:getComponent("Position")
    if not position then
        self.targetOpacity = 0.0
        return
    end

    -- Use OxygenSystem's safe zone check (using player center)
    local playerCenterX, playerCenterY = EntityUtils.getEntityVisualCenter(player, position)
    local isInSafeZone = self.oxygenSystem:isInReactorSafeZone(playerCenterX, playerCenterY)

    -- Show vignette when OUTSIDE safezone
    self.targetOpacity = isInSafeZone and 0.0 or 1.0

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
function SafezoneVignetteSystem:draw()
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

return SafezoneVignetteSystem

