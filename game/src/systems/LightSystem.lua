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
        if position and lightComp and lightComp.enabled ~= false then
            ensureLightCreated(self, entity)
            if lightComp.lightRef then
                local x = position.x + (lightComp.offsetX or 0)
                local y = position.y + (lightComp.offsetY or 0)
                lightComp.lightRef:SetPosition(x, y, 1)
            end
        end
    end
end

return LightSystem


