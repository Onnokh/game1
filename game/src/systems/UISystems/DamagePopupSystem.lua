local System = require("src.core.System")
local EventBus = require("src.utils.EventBus")
local fonts = require("src.utils.fonts")
local ui_text = require("src.utils.ui_text")
local ShaderManager = require("src.utils.ShaderManager")
local gameState = require("src.core.GameState")

---@class DamagePopupSystem : System
---@field popups table
---@field ecsWorld World
local DamagePopupSystem = System:extend("DamagePopupSystem", {})

function DamagePopupSystem.new(ecsWorld)
	---@class DamagePopupSystem
	local self = System.new({})
	setmetatable(self, DamagePopupSystem)
	self.popups = {}
	self.ecsWorld = ecsWorld
	self.isWorldSpace = false -- This UI system draws in screen space with world-to-screen conversion

	EventBus.subscribe("entityDamaged", function(payload)
		-- payload: { target, amount }
		local target = payload and payload.target or nil
		local amount = payload and payload.amount or 0
		if not target then return end
		local pos = target:getComponent("Position")
		if not pos then return end

    if target:hasTag("Player") then
      return
    end

		-- Calculate spawn position anchored to the healthbar
		local worldX, worldY, entityWidth
		local healthBar = target:getComponent("HealthBar")

		if healthBar then
			-- Get entity position (same logic as HealthBarSystem)
			local entityX, entityY
			local physicsCollision = target:getComponent("PhysicsCollision")
			if physicsCollision and physicsCollision:hasCollider() then
				-- Get the actual physics body center position
				local bodyX, bodyY = physicsCollision.collider.body:getPosition()
				local w = physicsCollision.width
				local h = physicsCollision.height
				entityX = bodyX - w * 0.5
				entityY = bodyY - h * 0.5
				entityWidth = w
			else
				-- Fallback: use Position and SpriteRenderer for entities without PhysicsCollision (like Reactor)
				entityX = pos.x
				entityY = pos.y
				local sr = target:getComponent("SpriteRenderer")
				entityWidth = (sr and sr.width) or 24
			end

			-- Get healthbar position and spawn above it
			local hbX, hbY = healthBar:getPosition(entityX, entityY, entityWidth)
			worldX = hbX + healthBar.width * 0.5 -- Center of healthbar
			worldY = hbY - 6 -- 6 pixels above healthbar
		end

		-- Create advanced damage number with same features as original system
		table.insert(self.popups, {
			text = tostring(math.floor(amount + 0.5)),
			owner = target,
			offsetX = 0,
			offsetY = -8,
			localX = 0,
			localY = 0,
			worldX = worldX,
			worldY = worldY - 4,
			vx = 0,
			vy = -32, -- float upward
			ttl = 0.8, -- seconds
			ttlMax = 0.8,
			scale = 1.0,
			color = { r = 1.0, g = 1.0, b = 1.0, a = 1.0 },
			stickToOwner = true,
			jitterX = (love.math.random() - 0.5) * entityWidth, -- ~[-entityWidth/2, entityWidth/2] px horizontal jitter relative to entity width
			jitterY = (love.math.random() - 0.5) * 15, -- ~[-5,5] px initial vertical jitter
		})
	end)

	return self
end

function DamagePopupSystem:update(dt)
	for i = #self.popups, 1, -1 do
		local p = self.popups[i]
		-- Follow owner if available
		if p.owner and p.stickToOwner and p.owner.active ~= false then
			local pos = p.owner:getComponent("Position")
			if pos then
				local healthBar = p.owner:getComponent("HealthBar")

				if healthBar then
					-- Anchor to healthbar position
					local entityX, entityY, entityWidth
					local physicsCollision = p.owner:getComponent("PhysicsCollision")
					if physicsCollision and physicsCollision:hasCollider() then
						local bodyX, bodyY = physicsCollision.collider.body:getPosition()
						local w = physicsCollision.width
						local h = physicsCollision.height
						entityX = bodyX - w * 0.5
						entityY = bodyY - h * 0.5
						entityWidth = w
					else
						local sr = p.owner:getComponent("SpriteRenderer")
						entityX = pos.x
						entityY = pos.y
						entityWidth = (sr and sr.width) or 24
					end

					-- Get healthbar position and position above it
					local hbX, hbY = healthBar:getPosition(entityX, entityY, entityWidth)
					p.worldX = hbX + healthBar.width * 0.5 + p.offsetX + p.localX
					p.worldY = hbY - 6 + p.offsetY + p.localY
				else
					-- Fallback: use SpriteRenderer
					local sr = p.owner:getComponent("SpriteRenderer")
					local w = (sr and sr.width) or 24
					p.worldX = pos.x + w * 0.5 + p.offsetX + p.localX
					p.worldY = pos.y - 4 + p.offsetY + p.localY
				end
			end
		end

		p.ttl = p.ttl - dt
		if p.ttl <= 0 then
			table.remove(self.popups, i)
		end
	end
end

function DamagePopupSystem:draw()

	for _, p in ipairs(self.popups) do
		-- Draw in screen space so text is not scaled by camera
		local r, g, b, a = love.graphics.getColor()
		love.graphics.setColor(p.color.r, p.color.g, p.color.b, p.color.a)

		-- Convert world position to screen coordinates
		local screenX, screenY = p.worldX or 0, p.worldY or 0
		if gameState and gameState.camera and gameState.camera.toScreen then
			screenX, screenY = gameState.camera:toScreen(screenX, screenY)
		end

    -- Choose an appropriate font size so it appears crisp at current zoom
    local cameraScale = (gameState and gameState.camera and gameState.camera.scale) or 1
    local basePx = 14
    local font = nil
    font = select(1, fonts.getCameraScaled(basePx, cameraScale, 8))

		-- Draw at UI origin so it is not affected by camera transforms
		local prevFont = love.graphics.getFont()
		love.graphics.push()
		love.graphics.origin()
		if font then love.graphics.setFont(font) end

		-- Center horizontally using the actual font width (no camera scale applied)
		local textWidth = (font and font:getWidth(p.text) or 0)
		local halfW = textWidth * 0.5
		local x = math.floor(screenX - halfW + 0.5)
		local y = math.floor(screenY + 0.5)

		-- Damage number animation via shader + transforms
		local ttlMax = p.ttlMax or p.ttl or 1
		local progress = 1 - math.max(0, math.min(1, (p.ttl or 0) / ttlMax))
		local moveUp = 20 -- pixels to move up over lifetime
		local startScale, endScale = 1.1, 0.3
		local currentScale = startScale + (endScale - startScale) * progress

		-- Apply movement up and scale in screen space around the text center (x+halfW, y)
		love.graphics.push()
		love.graphics.translate(x + halfW, y - moveUp * progress)
		love.graphics.scale(currentScale, currentScale)

		-- Set shader uniforms (shader doesn't change position, but can be used for effects)
		local shader = ShaderManager.getShader("damage_number")
		if shader then
			love.graphics.setShader(shader)
			ShaderManager.setUniform(shader, "Progress", progress)
			ShaderManager.setUniform(shader, "MoveUp", moveUp)
			ShaderManager.setUniform(shader, "StartScale", startScale)
			ShaderManager.setUniform(shader, "EndScale", endScale)
			ShaderManager.setUniform(shader, "JitterX", p.jitterX or 0)
			ShaderManager.setUniform(shader, "JitterY", p.jitterY or 0)
		end

        -- Draw outlined text with approx 2px outline regardless of current scale
        local outlinePx = 2 / currentScale
        ui_text.drawOutlinedText(p.text, -halfW, 0, {p.color.r, p.color.g, p.color.b, p.color.a}, {0,0,0,p.color.a}, outlinePx)

		-- Reset shader and transforms for UI layer
		if shader then love.graphics.setShader() end
		love.graphics.pop() -- pop scale/translate

		love.graphics.pop()
		if prevFont then love.graphics.setFont(prevFont) end
		love.graphics.setColor(r, g, b, a)
	end
end

return DamagePopupSystem


