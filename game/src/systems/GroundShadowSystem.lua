local System = require("src.core.System")

---@class GroundShadowSystem : System
local GroundShadowSystem = System:extend("GroundShadowSystem", {"Position", "PhysicsCollision", "GroundShadow"})

---Draw semi-transparent ellipse shadows under entities
function GroundShadowSystem:draw()
	if not self.entities then return end
	for _, entity in ipairs(self.entities) do
		local position = entity:getComponent("Position")
		local physicsCollision = entity:getComponent("PathfindingCollision")
		local shadow = entity:getComponent("GroundShadow")
		if position and physicsCollision and shadow and shadow.enabled then
			-- Determine ellipse size based on physics collider dimensions
			local width = (physicsCollision.width or 0) * (shadow.widthFactor or 1)
			local height = (physicsCollision.height or 0) * (shadow.heightFactor or 1)
			if width > 0 and height > 0 then
				-- Center at the collider's lowest position (bottom-center)
				local x = position.x + (physicsCollision.offsetX or 0) + (physicsCollision.width * 0.5)
				local y = position.y + (physicsCollision.offsetY or 0) + physicsCollision.height + (shadow.offsetY or 0)

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


