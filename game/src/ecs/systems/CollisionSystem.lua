local System = require("src.ecs.System")

---@class CollisionSystem : System
---@field physicsWorld any
local CollisionSystem = setmetatable({}, {__index = System})
CollisionSystem.__index = CollisionSystem

---Create a new CollisionSystem
---@param physicsWorld any The Breezefield physics world
---@return CollisionSystem|System
function CollisionSystem.new(physicsWorld)
	local self = System.new({"Position", "Collision"})
	setmetatable(self, CollisionSystem)
	---@type any
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
			-- Push basic material properties if set on component
			if collision.collider then
				collision.collider:setType(collision.type or "dynamic")
				collision.collider:setRestitution(collision.restitution or 0)
				collision.collider:setFriction(collision.friction or 0)
				collision.collider:setLinearDamping(collision.linearDamping or 0)
			end
		end
	end
end

return CollisionSystem


