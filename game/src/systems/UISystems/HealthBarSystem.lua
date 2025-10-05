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
		local spriteRenderer = entity:getComponent("SpriteRenderer")

		if position and health and healthBar and healthBar.visible and not health.isDead then
			local healthPercentage = health:getHealthPercentage()
			if healthPercentage < 1.0 then
				local entityWidth = spriteRenderer and spriteRenderer.width or 32
				local x, y = healthBar:getPosition(position.x, position.y, entityWidth)
				healthBar:draw(x, y, healthPercentage)
			end
		end
	end
end

return HealthBarSystem
