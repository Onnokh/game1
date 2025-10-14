local System = require("src.core.System")
local luven = require("lib.luven.luven")

---@class LightSystem : System
local LightSystem = System:extend("LightSystem", {"Position", "Light"})

---Initialize - no need for lightWorld reference with Luven
function LightSystem:setWorld(world)
    System.setWorld(self, world)
end

---Ensure a light exists for a specific light config
---@param lightConfig table Single light configuration from the lights array
---@param x number Light x position
---@param y number Light y position
local function ensureLightCreated(self, lightConfig, x, y)
    if not lightConfig or lightConfig.enabled == false then return end
    if lightConfig.lightId then return end -- Already created

    -- Convert 0-255 color to 0-1 range for Luven
    local r = (lightConfig.r or 255) / 255
    local g = (lightConfig.g or 255) / 255
    local b = (lightConfig.b or 255) / 255

    -- Convert radius to power (Luven uses power as a multiplier)
    -- Typical radius is 400, and we want that to be a reasonable size
    -- The light sprite is 256px, so power of ~1.5-2 works well for radius 400
    local power = (lightConfig.radius or 400) / 256

    -- Create light based on whether it's flickering
    if lightConfig.flicker then
        -- Create flickering light
        local flickerSpeed = lightConfig.flickerSpeed or 8
        local rAmp = (lightConfig.flickerRadiusAmplitude or 10) / 255
        local aAmp = (lightConfig.flickerAlphaAmplitude or 20) / 255

        -- Calculate power range
        local basePower = power
        local minPower = math.max(0, basePower - (lightConfig.flickerRadiusAmplitude or 10) / 256)
        local maxPower = basePower + (lightConfig.flickerRadiusAmplitude or 10) / 256

        -- Calculate color range (with alpha variation)
        local minAlpha = math.max(0, 1 - aAmp)
        local maxAlpha = math.min(1, 1 + aAmp)

        local colorRange = luven.newColorRange(r, g, b, r, g, b, minAlpha, maxAlpha)
        local powerRange = luven.newNumberRange(minPower, maxPower)
        local speedRange = luven.newNumberRange(0.05, 0.15) -- Random flicker timing

        lightConfig.lightId = luven.addFlickeringLight(
            x, y,
            colorRange,
            powerRange,
            speedRange,
            luven.lightShapes.round -- default shape
        )
    else
        -- Create normal light
        local color = luven.newColor(r, g, b, 1)
        lightConfig.lightId = luven.addNormalLight(
            x, y,
            color,
            power,
            luven.lightShapes.round -- default shape
        )
    end
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
                -- Calculate light position
                local defaultOX = spriteRenderer and (spriteRenderer.width or 0) / 2 or 0
                local defaultOY = spriteRenderer and (spriteRenderer.height or 0) / 2 or 0
                local lightX = position.x + (lightConfig.offsetX ~= nil and lightConfig.offsetX or defaultOX)
                local lightY = position.y + (lightConfig.offsetY ~= nil and lightConfig.offsetY or defaultOY)
                local lightRadius = lightConfig.radius or 400

                -- Check if light is visible in camera view
                local visible = isLightVisible(lightX, lightY, lightRadius, camera)

                -- If light is disabled or not visible, remove it
                if (lightConfig.enabled == false or not visible) and lightConfig.lightId then
                    luven.removeLight(lightConfig.lightId)
                    lightConfig.lightId = nil
                elseif lightConfig.enabled ~= false and visible then
                    -- Ensure light exists
                    ensureLightCreated(self, lightConfig, lightX, lightY)

                    -- Update light position
                    if lightConfig.lightId then
                        luven.setLightPosition(lightConfig.lightId, lightX, lightY)
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
                if lightConfig.lightId then
                    luven.removeLight(lightConfig.lightId)
                    lightConfig.lightId = nil
                end
            end
        end
    end
end

return LightSystem
