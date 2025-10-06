local System = require("src.core.System")

---@class LightSystem : System
---@field lightWorld any
local LightSystem = System:extend("LightSystem", {"Position", "Light"})

---Create a new LightSystem
---@param lightWorld any
---@return LightSystem
function LightSystem.new(lightWorld)
    ---@class LightSystem
    local self = System.new({"Position", "Light"})
    setmetatable(self, LightSystem)
    self.lightWorld = lightWorld
    return self
end

---Ensure a light exists on the entity
---@param entity Entity
local function ensureLightCreated(self, entity)
    if not entity or not self or not self.lightWorld then return end
    local lightComp = entity:getComponent("Light")
    if not lightComp or lightComp.enabled == false then return end
    if lightComp.lightRef then return end

    local Light = require("shadows.Light")
    local light = Light:new(self.lightWorld, lightComp.radius)
    light:SetColor(lightComp.r, lightComp.g, lightComp.b, lightComp.a)
    lightComp.lightRef = light
end

---Update
---@param dt number
function LightSystem:update(dt)
    if not self or not self.entities then return end
    for _, entity in ipairs(self.entities) do
        local position = entity:getComponent("Position")
        local lightComp = entity:getComponent("Light")
        local spriteRenderer = entity:getComponent("SpriteRenderer")

        if position and lightComp then
            -- If light is disabled and has a lightRef, remove it
            if lightComp.enabled == false and lightComp.lightRef then
                lightComp.lightRef:Remove()
                lightComp.lightRef = nil
                print("Light removed from world")
            elseif lightComp.enabled ~= false then
                ensureLightCreated(self, entity)
                if lightComp.lightRef then
                    local defaultOX = spriteRenderer and (spriteRenderer.width or 0) / 2 or 0
                    local defaultOY = spriteRenderer and (spriteRenderer.height or 0) / 2 or 0
                    local x = position.x + (lightComp.offsetX ~= nil and lightComp.offsetX or defaultOX)
                    local y = position.y + (lightComp.offsetY ~= nil and lightComp.offsetY or defaultOY)
                    lightComp.lightRef:SetPosition(x, y, 1)

                    -- Apply flicker if enabled
                    if lightComp.flicker then
                        local t = love.timer.getTime()
                        local speed = lightComp.flickerSpeed or 8
                        local rAmp = lightComp.flickerRadiusAmplitude or 10
                        local aAmp = lightComp.flickerAlphaAmplitude or 20
                        local baseRadius = lightComp.radius or 400
                        local baseA = lightComp.a or 255

                        -- Simple layered noise using sines for organic flicker
                        local n = math.sin(t * speed) * 0.6 + math.sin(t * (speed * 1.7) + 1.3) * 0.4
                        local radius = baseRadius + n * rAmp
                        local alpha = math.max(0, math.min(255, baseA + n * aAmp))

                        lightComp.lightRef:SetRadius(radius)
                        lightComp.lightRef:SetColor(lightComp.r, lightComp.g, lightComp.b, alpha)
                    else
                        -- Ensure base properties when not flickering
                        if lightComp.lightRef.GetRadius and lightComp.lightRef:GetRadius() ~= lightComp.radius then
                            lightComp.lightRef:SetRadius(lightComp.radius)
                        end
                        local cr, cg, cb, ca = lightComp.lightRef:GetColor()
                        if cr ~= lightComp.r or cg ~= lightComp.g or cb ~= lightComp.b or ca ~= lightComp.a then
                            lightComp.lightRef:SetColor(lightComp.r, lightComp.g, lightComp.b, lightComp.a)
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
        if lightComp and lightComp.lightRef then
            lightComp.lightRef:Remove()
            lightComp.lightRef = nil
        end
    end
end

return LightSystem


