-- Import System base class
local System = require("src.core.System")

---@class FlashEffectSystem : System
local FlashEffectSystem = setmetatable({}, {__index = System})
FlashEffectSystem.__index = FlashEffectSystem

---Create a new FlashEffectSystem
---@return FlashEffectSystem|System
function FlashEffectSystem.new()
    local self = System.new({"FlashEffect"})
    setmetatable(self, FlashEffectSystem)
    return self
end

---Update all entities with FlashEffect components
---@param dt number Delta time
function FlashEffectSystem:update(dt)
    for _, entity in ipairs(self.entities) do
        local flashEffect = entity:getComponent("FlashEffect")

        if flashEffect then
            -- Update the flash effect
            local isStillFlashing = flashEffect:update(dt)

            -- Note: Shader uniforms are set in RenderSystem when drawing

            -- Remove the component if flash is complete
            if not isStillFlashing then
                entity:removeComponent("FlashEffect")
            end
        end
    end
end

return FlashEffectSystem
