local System = require("src.core.System")
local CustomLightRenderer = require("src.utils.CustomLightRenderer")

---@class LightSystem : System
local LightSystem = System:extend("LightSystem", {"Position", "Light"})

---Initialize - no need for lightWorld reference with Luven
function LightSystem:setWorld(world)
    System.setWorld(self, world)
end

---Remove an entity from this system and clean up its lights
---@param entity Entity The entity to remove
function LightSystem:removeEntity(entity)
    -- Clean up lights before removing entity
    local light = entity:getComponent("Light")
    if light then
        for _, lightConfig in ipairs(light.lights) do
            if lightConfig.lightId then
                CustomLightRenderer.removeLight(lightConfig.lightId)
            end
            lightConfig.enabled = false
            lightConfig.lightId = nil
        end
    end

    -- Call parent removeEntity method
    System.removeEntity(self, entity)
end

---Ensure a light exists for a specific light config
---@param lightConfig table Single light configuration from the lights array
---@param x number Light x position
---@param y number Light y position
local function ensureLightCreated(self, lightConfig, x, y)
    if not lightConfig or lightConfig.enabled == false then return end
    if lightConfig.lightId then return end -- Already created

    lightConfig.lightId = CustomLightRenderer.addLight(
        x, y,
        lightConfig.radius or 400,
        lightConfig.r or 255,
        lightConfig.g or 255,
        lightConfig.b or 255,
        lightConfig.a or 255
    )
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
                    CustomLightRenderer.removeLight(lightConfig.lightId)
                    lightConfig.lightId = nil
                elseif lightConfig.enabled ~= false and visible then
                    -- Ensure light exists
                    ensureLightCreated(self, lightConfig, lightX, lightY)

                    -- Update light position
                    if lightConfig.lightId then
                        CustomLightRenderer.setLightPosition(lightConfig.lightId, lightX, lightY)
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
                    CustomLightRenderer.removeLight(lightConfig.lightId)
                    lightConfig.lightId = nil
                end
            end
        end
    end
end

return LightSystem
