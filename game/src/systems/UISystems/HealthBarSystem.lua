local System = require("src.core.System")

---@class HealthBarSystem : System
---@field ecsWorld World
local HealthBarSystem = System:extend("HealthBarSystem", {})

function HealthBarSystem.new(ecsWorld)
	---@class HealthBarSystem
	local self = System.new({})
	setmetatable(self, HealthBarSystem)
	self.ecsWorld = ecsWorld
	self.isWorldSpace = true -- This UI system draws in world space

  return self
end

---Draw world-space health bars for entities that have Health and HealthBar
function HealthBarSystem:draw()
	local world = self.ecsWorld
	if not world then return end
	local entities = world:getEntitiesWith({ "Position", "Health", "HealthBar" })
	for _, entity in ipairs(entities) do
		local position = entity:getComponent("Position")
		local health = entity:getComponent("Health")
		local healthBar = entity:getComponent("HealthBar")

		if position and health and healthBar and healthBar.visible and not health.isDead then
			local healthPercentage = health:getHealthPercentage()
			if healthBar.alwaysVisible or healthPercentage < 1.0 then
				-- Use PhysicsCollision position if available
				local entityX, entityY, entityWidth
				local physicsCollision = entity:getComponent("PhysicsCollision")
				if physicsCollision and physicsCollision:hasCollider() then
					-- Get the actual physics body center position
					local bodyX, bodyY = physicsCollision.collider.body:getPosition()
					local w = physicsCollision.width
					local h = physicsCollision.height
					entityX = bodyX - w * 0.5
					entityY = bodyY - h * 0.5
					entityWidth = w
				else
					-- Fall back to Position + SpriteRenderer
					local spriteRenderer = entity:getComponent("SpriteRenderer")
					entityX = position.x
					entityY = position.y
					entityWidth = spriteRenderer and spriteRenderer.width or 32
				end

				local x, y = healthBar:getPosition(entityX, entityY, entityWidth)
				healthBar:draw(x, y, healthPercentage)
			end
		end
	end
end

return HealthBarSystem
