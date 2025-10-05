local FontManager = require("src.utils.FontManager")

local fonts = {}

---Get a UI font at a fixed pixel size
---@param px number
---@return love.Font|nil
function fonts.getUIFont(px)
	return FontManager.getDetermination(px)
end

---Get a UI font scaled for the current camera zoom
---@param basePx number base pixel size (e.g. 14)
---@param cameraScale number|nil optional camera scale (defaults to 1)
---@param minPx number|nil minimum pixel size (defaults to 8)
---@return love.Font|nil, number targetPx
function fonts.getCameraScaled(basePx, cameraScale, minPx)
	local scale = cameraScale or 1
	local minSize = minPx or 8
	local targetPx = math.max(minSize, math.floor(basePx * scale + 0.5))
	return FontManager.getDetermination(targetPx), targetPx
end

return fonts


