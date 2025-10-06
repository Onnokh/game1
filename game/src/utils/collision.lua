local CollisionUtils = {}

---Axis-aligned bounding box overlap using PhysicsCollision components
---@param physA table
---@param physB table
---@return boolean
function CollisionUtils.aabbOverlaps(physA, physB)
	if not physA or not physB or not physA.hasCollider or not physB.hasCollider then return false end
	if not physA:hasCollider() or not physB:hasCollider() then return false end

	local ax, ay = physA:getPosition()
	local aw, ah = physA.width, physA.height
	local bx, by = physB:getPosition()
	local bw, bh = physB.width, physB.height

	local aLeft, aRight = ax, ax + aw
	local aTop, aBottom = ay, ay + ah
	local bLeft, bRight = bx, bx + bw
	local bTop, bBottom = by, by + bh

	return not (aRight < bLeft or aLeft > bRight or aBottom < bTop or aTop > bBottom)
end

return CollisionUtils


