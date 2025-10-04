local System = require("src.core.System")

---@class CollisionSystem : System
---@field physicsWorld love.World
local CollisionSystem = System:extend("CollisionSystem", {"Position", "Collision"})

---Create a new CollisionSystem
---@param physicsWorld love.World
---@return CollisionSystem
function CollisionSystem.new(physicsWorld)
    local self = System.new({"Position", "Collision"})
    setmetatable(self, CollisionSystem)
    self.physicsWorld = physicsWorld
    return self
end

---On update, ensure colliders exist for entities lacking one
---@param dt number
function CollisionSystem:update(dt)
	if not self or not self.entities then return end
	for _, entity in ipairs(self.entities) do
		local position = entity:getComponent("Position")
		local collision = entity:getComponent("Collision")
		if position and collision and not collision:hasCollider() and self.physicsWorld then
			collision:createCollider(self.physicsWorld, position.x, position.y)
		end
	end
end

return CollisionSystem


