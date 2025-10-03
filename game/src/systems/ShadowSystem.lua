local System = require("src.core.System")

---@class ShadowSystem : System
---@field lightWorld any
local ShadowSystem = setmetatable({}, {__index = System})
ShadowSystem.__index = ShadowSystem

---Create a new ShadowSystem
---@param lightWorld any The Shädows LightWorld instance
---@return ShadowSystem
function ShadowSystem.new(lightWorld)
	---@class ShadowSystem
	local self = System.new({"Position", "CastableShadow"})
	setmetatable(self, ShadowSystem)
	-- Store LightWorld reference on the instance
	self.lightWorld = lightWorld
	return self
end

---Ensure bodies/shapes exist for entity shadows
---@param entity Entity
local function ensureShadowCreated(self, entity)
	if not entity then return end
	local CastableShadow = entity:getComponent("CastableShadow")
	if not CastableShadow or CastableShadow.enabled == false then return end
	if CastableShadow.body then return end
	if not self or not self.lightWorld then return end

	local Body = require("shadows.Body")
	local PolygonShadow = require("shadows.ShadowShapes.PolygonShadow")

	local body = Body:new(self.lightWorld)
	CastableShadow.body = body
	CastableShadow.shapeRefs = {}

	-- Create shape(s)
	if CastableShadow.shape == "rectangle" then
		local w, h = CastableShadow.width, CastableShadow.height
		-- Rect from (0,0) in local body space
		local shape = PolygonShadow:new(body, 0, 0, w, 0, w, h, 0, h)
		CastableShadow.shapeRefs[1] = shape
	elseif CastableShadow.shape == "polygon" and CastableShadow.points and #CastableShadow.points >= 6 then
		local shape = PolygonShadow:new(body, table.unpack(CastableShadow.points))
		CastableShadow.shapeRefs[1] = shape
	end
end

---Update all entities (sync body positions)
---@param dt number
function ShadowSystem:update(dt)
	if not self or not self.entities then return end
	for _, entity in ipairs(self.entities) do
		local position = nil
		local shadow = nil
		if entity and entity.getComponent then
			position = entity:getComponent("Position")
			shadow = entity:getComponent("CastableShadow")
		end
		if position and shadow and shadow.enabled ~= false then
			ensureShadowCreated(self, entity)
			if shadow.body then
				local px = position.x or 0
				local py = position.y or 0
				local ox = shadow.offsetX or 0
				local oy = shadow.offsetY or 0
				shadow.body:SetPosition(px + ox, py + oy, 1)
			end
		end
	end
end

return ShadowSystem


