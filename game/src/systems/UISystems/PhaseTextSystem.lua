local System = require("src.core.System")
local PhaseText = require("src.ui.PhaseText")

---@class PhaseTextSystem : System
---@field isWorldSpace boolean
---@field widget any
local PhaseTextSystem = System:extend("PhaseTextSystem", {})

function PhaseTextSystem.new()
    local self = System.new({})
    setmetatable(self, PhaseTextSystem)
    self.isWorldSpace = false
    self.widget = PhaseText.new()
    return self
end

function PhaseTextSystem:draw()
    if self.widget and self.widget.draw then
        self.widget:draw()
    end
end

return PhaseTextSystem


