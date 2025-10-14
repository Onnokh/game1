local System = require("src.core.System")

---@class SiegeIndicatorSystem : System
---@field ecsWorld World
---@field skullIcon love.Image
local SiegeIndicatorSystem = System:extend("SiegeIndicatorSystem", {})

function SiegeIndicatorSystem.new(ecsWorld)
	---@class SiegeIndicatorSystem
	local self = System.new()
	setmetatable(self, SiegeIndicatorSystem)
	self.ecsWorld = ecsWorld
	self.isWorldSpace = true -- This UI system draws in world space (but also screen space for edges)

	-- Load the skull icon
	self.skullIcon = love.graphics.newImage("resources/icons/siege.png")
	self.iconSize = 8 -- Base size 8x8 pixels
	self.iconScale = 0.5 -- Scale down to 4x4 pixels
	self.pulseTime = 0 -- Time tracker for pulse animation

	return self
end

---Update the pulse animation
function SiegeIndicatorSystem:update(dt)
	self.pulseTime = self.pulseTime + dt
end

---Calculate intersection point of a ray from center to a point with the screen rectangle
---@param centerX number Screen center X
---@param centerY number Screen center Y
---@param targetX number Target screen X
---@param targetY number Target screen Y
---@param screenWidth number Screen width
---@param screenHeight number Screen height
---@return number, number Intersection X and Y on screen edge
local function getScreenEdgeIntersection(centerX, centerY, targetX, targetY, screenWidth, screenHeight)
	-- Direction vector from center to target
	local dx = targetX - centerX
	local dy = targetY - centerY

	-- Normalize direction
	local length = math.sqrt(dx * dx + dy * dy)
	if length == 0 then
		return centerX, centerY
	end
	dx = dx / length
	dy = dy / length

	-- Screen bounds (with margin to keep icons away from edge)
	local margin = 16
	local left = margin
	local right = screenWidth - margin
	local top = margin
	local bottom = screenHeight - margin

	-- Calculate intersections with all four edges
	local intersections = {}

	-- Left edge (x = left)
	if dx < 0 then
		local t = (left - centerX) / dx
		local y = centerY + t * dy
		if y >= top and y <= bottom then
			table.insert(intersections, {x = left, y = y, t = t})
		end
	end

	-- Right edge (x = right)
	if dx > 0 then
		local t = (right - centerX) / dx
		local y = centerY + t * dy
		if y >= top and y <= bottom then
			table.insert(intersections, {x = right, y = y, t = t})
		end
	end

	-- Top edge (y = top)
	if dy < 0 then
		local t = (top - centerY) / dy
		local x = centerX + t * dx
		if x >= left and x <= right then
			table.insert(intersections, {x = x, y = top, t = t})
		end
	end

	-- Bottom edge (y = bottom)
	if dy > 0 then
		local t = (bottom - centerY) / dy
		local x = centerX + t * dx
		if x >= left and x <= right then
			table.insert(intersections, {x = x, y = bottom, t = t})
		end
	end

	-- Find the closest intersection (smallest positive t)
	local closest = nil
	for _, intersection in ipairs(intersections) do
		if intersection.t > 0 and (not closest or intersection.t < closest.t) then
			closest = intersection
		end
	end

	if closest then
		return closest.x, closest.y
	end

	-- Fallback to center if no intersection found
	return centerX, centerY
end

---Draw world-space skull indicators for siege attackers
function SiegeIndicatorSystem:draw()
	local world = self.ecsWorld
	if not world then return end

	-- Get GameState for camera access
	local GameState = require("src.core.GameState")
	local camera = GameState.camera
	if not camera then return end

	-- Get screen dimensions
	local screenWidth = love.graphics.getWidth()
	local screenHeight = love.graphics.getHeight()
	local screenCenterX = screenWidth / 2
	local screenCenterY = screenHeight / 2

	-- Get visible area in world coordinates
	local visibleX, visibleY, visibleW, visibleH = camera:getVisible()

	-- Get all siege attacker entities
	local siegeEntities = world:getEntitiesWithTag("SiegeAttacker")

	for _, entity in ipairs(siegeEntities) do
		local position = entity:getComponent("Position")
		local physicsCollision = entity:getComponent("PhysicsCollision")
		local health = entity:getComponent("Health")

		-- Skip dead entities
		if health and health.isDead then
			goto continue
		end

		if position and physicsCollision and physicsCollision:hasCollider() then
			-- Get the actual physics body center position
			local bodyX, bodyY = physicsCollision.collider.body:getPosition()
			local w = physicsCollision.width
			local h = physicsCollision.height

			-- Calculate world position at top-center of collision box
			local scaledIconSize = self.iconSize * self.iconScale
			local worldX = bodyX - scaledIconSize / 2 -- Shift left by icon width
			local worldY = bodyY - h * 0.5 - 8 -- 6 pixels above the collision box

			-- Convert to screen coordinates to check if on-screen
			local screenX, screenY = camera:toScreen(worldX, worldY)

			-- Check if the entity is visible on screen
			local isOnScreen = screenX >= 0 and screenX <= screenWidth and
			                   screenY >= 0 and screenY <= screenHeight

			if isOnScreen then
				-- Draw skull in world space (above the mob)
				love.graphics.draw(
					self.skullIcon,
					worldX,
					worldY,
					0, -- rotation
					self.iconScale, -- scale X
					self.iconScale, -- scale Y
					self.iconSize / 2, -- origin X (center)
					self.iconSize / 2  -- origin Y (center)
				)
			else
				-- Draw skull at screen edge (in screen space)
				-- Save the current graphics state (camera transform)
				love.graphics.push()
				love.graphics.origin() -- Reset to screen space

				-- Calculate edge position
				local edgeX, edgeY = getScreenEdgeIntersection(
					screenCenterX,
					screenCenterY,
					screenX,
					screenY,
					screenWidth,
					screenHeight
				)

				-- Draw skull at edge (match onscreen size accounting for camera scale)
				-- Add pulse effect: oscillate between 0.9x and 1.1x size
				local pulseMultiplier = 1.0 + math.sin(self.pulseTime * 8) * 0.1
				local cameraScale = camera:getScale()
				local finalScale = self.iconScale * cameraScale * pulseMultiplier
				love.graphics.draw(
					self.skullIcon,
					edgeX,
					edgeY,
					0, -- rotation
					finalScale, -- scale X (adjusted for camera with pulse)
					finalScale, -- scale Y (adjusted for camera with pulse)
					self.iconSize / 2, -- origin X (center)
					self.iconSize / 2  -- origin Y (center)
				)

				-- Restore the graphics state (camera transform)
				love.graphics.pop()
			end
		end

		::continue::
	end
end

return SiegeIndicatorSystem

