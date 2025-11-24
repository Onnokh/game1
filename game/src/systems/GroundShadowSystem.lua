---@class GroundShadowSystem
---Configuration module for ground shadow rendering
---All shadow scale values are defined globally here
local GroundShadowSystem = {}

-- Global shadow configuration constants
GroundShadowSystem.SKEW_FACTOR = 0.3  -- Horizontal shear amount (shadow falls to the left)
GroundShadowSystem.SHADOW_SCALE_X = 1.0  -- Horizontal stretch multiplier
GroundShadowSystem.SHADOW_SCALE_Y = 0.5  -- Vertical compression multiplier

---Get actual sprite frame dimensions from Iffy based on what sprite is being drawn
---@param entity Entity The entity to get sprite dimensions for
---@param spriteRenderer SpriteRenderer The sprite renderer component
---@param animator Animator|nil The animator component if present
---@return number width Actual frame width
---@return number height Actual frame height
function GroundShadowSystem.getActualSpriteDimensions(entity, spriteRenderer, animator)
	local iffy = require("lib.iffy")
	local defaultWidth = spriteRenderer.width
	local defaultHeight = spriteRenderer.height

	-- For animated sprites, get dimensions from the first layer's current frame
	if animator and animator.layers and #animator.layers > 0 then
		local sheetName = animator.layers[1]
		if iffy.tilesets[sheetName] then
			return iffy.tilesets[sheetName][1] or defaultWidth, iffy.tilesets[sheetName][2] or defaultHeight
		end
	end

	-- For static sprites, get dimensions from the sprite's tileset
	if spriteRenderer.sprite then
		local spriteSheet = spriteRenderer.sprite
		if iffy.tilesets[spriteSheet] then
			return iffy.tilesets[spriteSheet][1] or defaultWidth, iffy.tilesets[spriteSheet][2] or defaultHeight
		end
	end

	-- Fallback to SpriteRenderer dimensions
	return defaultWidth, defaultHeight
end

return GroundShadowSystem


