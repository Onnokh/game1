local Component = require("src.core.Component")

---@class AttackCollider : Component
---@field collider table|nil
---@field lifetime number
---@field age number
---@field damage number
---@field knockback number
---@field attacker any
---@field hitEntities table
---@field angleRad number|nil
local AttackCollider = {}
AttackCollider.__index = AttackCollider

function AttackCollider.new(attacker, damage, knockback, lifetime)
	local self = setmetatable(Component.new("AttackCollider"), AttackCollider)
	self.collider = nil
	self.attacker = attacker
	self.damage = damage or 0
	self.knockback = knockback or 0
	self.lifetime = lifetime or 0.05
	self.age = 0
	self.hitEntities = {}
    self.angleRad = nil
	return self
end

---Create a rectangular sensor fixture at the given AABB
---@param physicsWorld love.World
---@param x number top-left x
---@param y number top-left y
---@param w number width
---@param h number height
function AttackCollider:createFixture(physicsWorld, x, y, w, h)
	if self.collider or not physicsWorld then return end
	local body = love.physics.newBody(physicsWorld, x + w/2, y + h/2, "dynamic")
	-- Allow rotation for oriented attack hitboxes
	body:setFixedRotation(false)
	body:setGravityScale(0)
	body:setLinearDamping(0)
	local shape = love.physics.newRectangleShape(w, h)
	local fixture = love.physics.newFixture(body, shape)
	fixture:setSensor(true)
	fixture:setUserData({ kind = "attack", component = self })
	self.collider = { body = body, shape = shape, fixture = fixture }
end

---Set the current rotation of the collider body (in radians)
---@param angleRad number
function AttackCollider:setAngle(angleRad)
    self.angleRad = angleRad
    if self.collider and self.collider.body then
        self.collider.body:setAngle(angleRad)
    end
end

function AttackCollider:update(dt)
	self.age = self.age + dt
end

function AttackCollider:isExpired()
	return self.age >= self.lifetime
end

function AttackCollider:destroy()
	if self.collider and self.collider.body then
		self.collider.body:destroy()
		self.collider = nil
	end
end

return AttackCollider


