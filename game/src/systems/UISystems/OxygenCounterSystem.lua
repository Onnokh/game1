local System = require("src.core.System")
local OxygenHUD = require("src.ui.OxygenHUD")

---@class OxygenCounterSystem : System
local OxygenCounterSystem = System:extend("OxygenCounterSystem", {})

---Create a new OxygenCounterSystem
---@param ecsWorld World
---@return OxygenCounterSystem
function OxygenCounterSystem.new(ecsWorld)
    ---@class OxygenCounterSystem
    local self = System.new()
    setmetatable(self, OxygenCounterSystem)
    self.ecsWorld = ecsWorld
    self.isWorldSpace = false -- This UI system draws in screen space

    return self
end

---Update the oxygen counter system
---@param dt number Delta time
function OxygenCounterSystem:update(dt)
    -- No update logic needed - oxygen display is handled in draw()
end

---Draw the oxygen counter
function OxygenCounterSystem:draw()
    if self.ecsWorld then
        OxygenHUD.draw(self.ecsWorld)
    end
end

return OxygenCounterSystem
