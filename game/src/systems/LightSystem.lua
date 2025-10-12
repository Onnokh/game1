local System = require("src.core.System")

---@class LightSystem : System
---@field lightWorld any
local LightSystem = System:extend("LightSystem", {"Position", "Light"})

---Initialize light world reference when world is set
function LightSystem:setWorld(world)
    System.setWorld(self, world)
    self.lightWorld = world and world.lightWorld or nil
end

---Ensure a light exists for a specific light config
---@param lightConfig table Single light configuration from the lights array
local function ensureLightCreated(self, lightConfig)
    if not self or not self.lightWorld then return end
    if not lightConfig or lightConfig.enabled == false then return end
    if lightConfig.lightRef then return end

    local Light = require("shadows.Light")
    -- If flickering, create canvas large enough for maximum radius
    local maxRadius = lightConfig.radius
    if lightConfig.flicker then
        maxRadius = maxRadius + (lightConfig.flickerRadiusAmplitude or 10)
        -- Add random offset so lights don't flicker in sync
        lightConfig.flickerOffset = math.random() * 1000
    end
    local light = Light:new(self.lightWorld, maxRadius)
    light:SetColor(lightConfig.r, lightConfig.g, lightConfig.b, lightConfig.a)

    -- Force canvas to be destroyed and recreated at correct size
    if lightConfig.flicker then
        light:DestroyCanvas()
        light:InitCanvas()
    end

    lightConfig.lightRef = light
end

---Check if a light position is visible in the camera view
---@param x number Light x position
---@param y number Light y position
---@param radius number Light radius
---@param camera table|nil Camera object
---@return boolean Whether the light is visible
local function isLightVisible(x, y, radius, camera)
    if not camera then return true end -- No camera means no culling

    local camX, camY = camera:getPosition()
    local camScale = camera:getScale()
    local screenW, screenH = love.graphics.getDimensions()
    local viewWidth = screenW / camScale
    local viewHeight = screenH / camScale

    -- Add margin based on light radius so lights just outside view still affect visible area
    local margin = radius * 1.2

    -- Check if light is within camera bounds (with margin)
    local isVisible = not (
        x + radius < camX - viewWidth/2 - margin or
        x - radius > camX + viewWidth/2 + margin or
        y + radius < camY - viewHeight/2 - margin or
        y - radius > camY + viewHeight/2 + margin
    )

    return isVisible
end

---Update
---@param dt number
function LightSystem:update(dt)
    if not self or not self.entities then return end

    -- Get camera from world for frustum culling
    local camera = self.world and self.world.camera or nil

    for _, entity in ipairs(self.entities) do
        local position = entity:getComponent("Position")
        local lightComp = entity:getComponent("Light")
        local spriteRenderer = entity:getComponent("SpriteRenderer")

        if position and lightComp and lightComp.lights then
            -- Iterate through all lights in the component
            for i, lightConfig in ipairs(lightComp.lights) do
                -- Calculate light position for visibility check
                local defaultOX = spriteRenderer and (spriteRenderer.width or 0) / 2 or 0
                local defaultOY = spriteRenderer and (spriteRenderer.height or 0) / 2 or 0
                local lightX = position.x + (lightConfig.offsetX ~= nil and lightConfig.offsetX or defaultOX)
                local lightY = position.y + (lightConfig.offsetY ~= nil and lightConfig.offsetY or defaultOY)
                local lightRadius = lightConfig.radius or 400

                -- Check if light is visible in camera view
                local visible = isLightVisible(lightX, lightY, lightRadius, camera)

                -- If light is disabled or not visible
                if (lightConfig.enabled == false or not visible) and lightConfig.lightRef then
                    -- Temporarily remove light from rendering (but keep the reference)
                    lightConfig.lightRef:SetPosition(lightX, lightY, 0) -- Z=0 disables the light
                elseif lightConfig.enabled ~= false and visible then
                    ensureLightCreated(self, lightConfig)
                    if lightConfig.lightRef then
                        lightConfig.lightRef:SetPosition(lightX, lightY, 1) -- Z=1 enables the light

                        -- Apply flicker if enabled
                        if lightConfig.flicker then
                            local t = love.timer.getTime() + (lightConfig.flickerOffset or 0)
                            local speed = lightConfig.flickerSpeed or 8
                            local rAmp = lightConfig.flickerRadiusAmplitude or 10
                            local aAmp = lightConfig.flickerAlphaAmplitude or 20
                            local baseRadius = lightConfig.radius or 400
                            local baseA = lightConfig.a or 255

                            local n = math.sin(t * speed) * 0.6 + math.sin(t * (speed * 1.7) + 1.3) * 0.4
                            local radius = baseRadius + n * rAmp
                            local alpha = math.max(0, math.min(255, baseA + n * aAmp))

                            lightConfig.lightRef:SetRadius(radius)
                            lightConfig.lightRef:SetColor(lightConfig.r, lightConfig.g, lightConfig.b, alpha)
                        end
                    end
                end
            end
        end
    end
end

---Cleanup method to remove all lights when system is destroyed
function LightSystem:cleanup()
    if not self or not self.entities then return end
    for _, entity in ipairs(self.entities) do
        local lightComp = entity:getComponent("Light")
        if lightComp and lightComp.lights then
            for i, lightConfig in ipairs(lightComp.lights) do
                if lightConfig.lightRef then
                    lightConfig.lightRef:Remove()
                    lightConfig.lightRef = nil
                end
            end
        end
    end
end

return LightSystem


