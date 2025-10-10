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

---Update
---@param dt number
function LightSystem:update(dt)
    if not self or not self.entities then return end
    for _, entity in ipairs(self.entities) do
        local position = entity:getComponent("Position")
        local lightComp = entity:getComponent("Light")
        local spriteRenderer = entity:getComponent("SpriteRenderer")

        if position and lightComp and lightComp.lights then
            -- Iterate through all lights in the component
            for i, lightConfig in ipairs(lightComp.lights) do
                -- If light is disabled and has a lightRef, remove it
                if lightConfig.enabled == false and lightConfig.lightRef then
                    lightConfig.lightRef:Remove()
                    lightConfig.lightRef = nil
                elseif lightConfig.enabled ~= false then
                    ensureLightCreated(self, lightConfig)
                    if lightConfig.lightRef then
                        local defaultOX = spriteRenderer and (spriteRenderer.width or 0) / 2 or 0
                        local defaultOY = spriteRenderer and (spriteRenderer.height or 0) / 2 or 0
                        local x = position.x + (lightConfig.offsetX ~= nil and lightConfig.offsetX or defaultOX)
                        local y = position.y + (lightConfig.offsetY ~= nil and lightConfig.offsetY or defaultOY)
                        lightConfig.lightRef:SetPosition(x, y, 1)

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


