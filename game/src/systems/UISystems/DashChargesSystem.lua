local System = require("src.core.System")
local DashChargesHUD = require("src.ui.DashChargesHUD")

---@class DashChargesSystem : System
---UI System that draws the dash charges HUD
local DashChargesSystem = System:extend("DashChargesSystem", {})

---Create a new DashChargesSystem
---@param ecsWorld World
---@return DashChargesSystem
function DashChargesSystem.new(ecsWorld)
    ---@class DashChargesSystem
    local self = System.new()
    setmetatable(self, DashChargesSystem)
    self.ecsWorld = ecsWorld
    self.isWorldSpace = false -- This UI system draws in screen space

    return self
end

---Draw the dash charges HUD
function DashChargesSystem:draw()
    if self.ecsWorld then
        print("Dash UI Debug - DashChargesSystem draw() called")
        DashChargesHUD.draw(self.ecsWorld)
    else
        print("Dash UI Debug - No ecsWorld in DashChargesSystem")
    end
end

return DashChargesSystem
