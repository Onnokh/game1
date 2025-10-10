local System = require("src.core.System")

---@class GroundShadowSystem : System
local GroundShadowSystem = System:extend("GroundShadowSystem", {"Position", "GroundShadow"})

-- Create a simple shadow texture once
local shadowImage
local function createShadowTexture()
	if shadowImage then return shadowImage end

	-- Create a pixelated circle manually
	local size = 16
	local imageData = love.image.newImageData(size, size)
	local centerX, centerY = size / 2, size / 2
	local radius = size / 2

	-- Draw a filled circle pixel by pixel
	for y = 0, size - 1 do
		for x = 0, size - 1 do
			local dx = x - centerX + 0.5
			local dy = y - centerY + 0.5
			local distance = math.sqrt(dx * dx + dy * dy)

			if distance <= radius then
				-- White pixel (will be tinted black when drawn)
				imageData:setPixel(x, y, 1, 1, 1, 1)
			else
				-- Transparent pixel
				imageData:setPixel(x, y, 0, 0, 0, 0)
			end
		end
	end

	-- Create image with nearest filtering for pixel-perfect rendering
	shadowImage = love.graphics.newImage(imageData)
	shadowImage:setFilter("nearest", "nearest")

	return shadowImage
end

---Draw semi-transparent ellipse shadows under entities
function GroundShadowSystem:draw()
	if not self.entities then return end

	local shadow = createShadowTexture()
	local imgSize = shadow:getWidth()

	for _, entity in ipairs(self.entities) do
		local position = entity:getComponent("Position")
		local shadowComp = entity:getComponent("GroundShadow")

		-- Try PathfindingCollision first, fall back to PhysicsCollision
		local collider = entity:getComponent("PathfindingCollision") or entity:getComponent("PhysicsCollision")

		if position and collider and shadowComp and shadowComp.enabled then
			-- Determine ellipse size based on collider dimensions
			local width = (collider.width or 0) * (shadowComp.widthFactor or 1)
			local height = (collider.height or 0) * (shadowComp.heightFactor or 1)
			if width > 0 and height > 0 then
				-- Center at the collider's lowest position (bottom-center)
				local x = position.x + (collider.offsetX or 0) + (collider.width * 0.5)
				local y = position.y + (collider.offsetY or 0) + collider.height + (shadowComp.offsetY or 0)

				-- Set dark color with configured alpha
				love.graphics.setColor(0, 0, 0, shadowComp.alpha or 0.35)
				-- Draw scaled shadow image
				love.graphics.draw(
					shadow,
					x,
					y,
					0,
					width / imgSize,
					height / imgSize,
					imgSize / 2,
					imgSize / 2
				)
			end
		end
	end
	-- Reset drawing color
	love.graphics.setColor(1, 1, 1, 1)
end

return GroundShadowSystem


