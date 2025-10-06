local System = require("src.core.System")
local ShaderManager = require("src.utils.ShaderManager")
local GameConstants = require("src.constants")

---@class SafezoneVignetteSystem : System
---Renders a vignette effect when player is outside the reactor safezone
local SafezoneVignetteSystem = System:extend("SafezoneVignetteSystem", {})

---Create a new SafezoneVignetteSystem
---@param ecsWorld World
---@return SafezoneVignetteSystem
function SafezoneVignetteSystem.new(ecsWorld)
    ---@class SafezoneVignetteSystem
    local self = System.new()
    setmetatable(self, SafezoneVignetteSystem)
    self.ecsWorld = ecsWorld
    self.isWorldSpace = false -- Screen space rendering
    self.vignetteOpacity = 0.0 -- 0 = no vignette, 1 = full vignette
    self.targetOpacity = 0.0 -- Target opacity to fade to
    self.fadeSpeed = 2.0 -- Speed of fade transition (units per second)
    return self
end

---Update the vignette based on player position
---@param dt number Delta time
function SafezoneVignetteSystem:update(dt)
    -- Find the player entity
    local player = self:findPlayerEntity()
    if not player then
        self.targetOpacity = 0.0
    else
        local position = player:getComponent("Position")
        if not position then
            self.targetOpacity = 0.0
        else
            -- Check if player is in safezone
            local isInSafeZone = self:isInReactorSafeZone(position.x, position.y)

            -- Show vignette when OUTSIDE safezone
            self.targetOpacity = isInSafeZone and 0.0 or 1.0
        end
    end

    -- Smoothly interpolate current opacity towards target
    if self.vignetteOpacity < self.targetOpacity then
        -- Fade in
        self.vignetteOpacity = math.min(self.vignetteOpacity + self.fadeSpeed * dt, self.targetOpacity)
    elseif self.vignetteOpacity > self.targetOpacity then
        -- Fade out
        self.vignetteOpacity = math.max(self.vignetteOpacity - self.fadeSpeed * dt, self.targetOpacity)
    end
end

---Check if position is within reactor safe zone
---@param x number X coordinate
---@param y number Y coordinate
---@return boolean True if in safe zone
function SafezoneVignetteSystem:isInReactorSafeZone(x, y)
    local reactor = self:findReactorEntity()
    if not reactor then
        return false
    end

    local reactorPosition = reactor:getComponent("Position")
    if not reactorPosition then
        return false
    end

    -- Calculate distance to reactor center (reactor sprite is 64x64)
    local reactorCenterX = reactorPosition.x + 32
    local reactorCenterY = reactorPosition.y + 32
    local dx = x - reactorCenterX
    local dy = y - reactorCenterY
    local distance = math.sqrt(dx * dx + dy * dy)

    return distance <= GameConstants.REACTOR_SAFE_RADIUS
end

---Find the player entity
---@return Entity|nil
function SafezoneVignetteSystem:findPlayerEntity()
    if not self.ecsWorld then
        return nil
    end

    for _, entity in ipairs(self.ecsWorld.entities) do
        if entity:hasTag("Player") then
            return entity
        end
    end

    return nil
end

---Find the reactor entity
---@return Entity|nil
function SafezoneVignetteSystem:findReactorEntity()
    if not self.ecsWorld then
        return nil
    end

    for _, entity in ipairs(self.ecsWorld.entities) do
        if entity:hasTag("Reactor") then
            return entity
        end
    end

    return nil
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

