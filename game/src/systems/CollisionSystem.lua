local System = require("src.core.System")

---@class CollisionSystem : System
---@field physicsWorld love.World
local CollisionSystem = System:extend("CollisionSystem", {"Position"})

---Create a new CollisionSystem
---@param physicsWorld love.World
---@return CollisionSystem
function CollisionSystem.new(physicsWorld)
    ---@class CollisionSystem
    local self = System.new({"Position"})
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
		if position and self.physicsWorld then
			-- Handle PathfindingCollision component (for pathfinding and physics collision)
			local pathfindingCollision = entity:getComponent("PathfindingCollision")
			if pathfindingCollision and not pathfindingCollision:hasCollider() then
				pathfindingCollision:createCollider(self.physicsWorld, position.x, position.y)
			end

			-- Handle PhysicsCollision component (for physics only)
			local physicsCollision = entity:getComponent("PhysicsCollision")
			if physicsCollision and not physicsCollision:hasCollider() then
				physicsCollision:createCollider(self.physicsWorld, position.x, position.y)
			end
		end
	end
end

return CollisionSystem


