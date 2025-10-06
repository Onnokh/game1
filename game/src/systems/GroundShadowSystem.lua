local System = require("src.core.System")

---@class GroundShadowSystem : System
local GroundShadowSystem = System:extend("GroundShadowSystem", {"Position", "GroundShadow"})

---Draw semi-transparent ellipse shadows under entities
function GroundShadowSystem:draw()
	if not self.entities then return end
	for _, entity in ipairs(self.entities) do
		local position = entity:getComponent("Position")
		local shadow = entity:getComponent("GroundShadow")

		-- Try PathfindingCollision first, fall back to PhysicsCollision
		local collider = entity:getComponent("PathfindingCollision") or entity:getComponent("PhysicsCollision")

		if position and collider and shadow and shadow.enabled then
			-- Determine ellipse size based on collider dimensions
			local width = (collider.width or 0) * (shadow.widthFactor or 1)
			local height = (collider.height or 0) * (shadow.heightFactor or 1)
			if width > 0 and height > 0 then
				-- Center at the collider's lowest position (bottom-center)
				local x = position.x + (collider.offsetX or 0) + (collider.width * 0.5)
				local y = position.y + (collider.offsetY or 0) + collider.height + (shadow.offsetY or 0)

				love.graphics.push()
				-- Set dark color with configured alpha
				love.graphics.setColor(0, 0, 0, shadow.alpha or 0.35)
				-- Draw ellipse via scaled circle for good quality
				love.graphics.translate(x, y)
				love.graphics.scale(width * 0.5, height * 0.5)
				love.graphics.circle("fill", 0, 0, 1)
				love.graphics.pop()
			end
		end
	end
	-- Reset drawing color
	love.graphics.setColor(1, 1, 1, 1)
end

return GroundShadowSystem


