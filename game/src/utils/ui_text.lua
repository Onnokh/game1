local ui_text = {}

---Draw text with an 8-directional outline for readability
---@param text string
---@param x number left-aligned x position
---@param y number baseline y position
---@param color table {r,g,b,a}
---@param outlineColor table {r,g,b,a}
---@param outlinePx number outline thickness in pixels (screen space)
function ui_text.drawOutlinedText(text, x, y, color, outlineColor, outlinePx)
	local r, g, b, a = love.graphics.getColor()
	-- Outline
	love.graphics.setColor(outlineColor[1] or outlineColor.r or 0, outlineColor[2] or outlineColor.g or 0, outlineColor[3] or outlineColor.b or 0, outlineColor[4] or outlineColor.a or 1)
	local o = outlinePx or 2
	love.graphics.print(text, x - o, y)
	love.graphics.print(text, x + o, y)
	love.graphics.print(text, x, y - o)
	love.graphics.print(text, x, y + o)
	love.graphics.print(text, x - o, y - o)
	love.graphics.print(text, x + o, y - o)
	love.graphics.print(text, x - o, y + o)
	love.graphics.print(text, x + o, y + o)
	-- Main
	love.graphics.setColor(color[1] or color.r or 1, color[2] or color.g or 1, color[3] or color.b or 1, color[4] or color.a or 1)
	love.graphics.print(text, x, y)
	-- Restore
	love.graphics.setColor(r, g, b, a)
end

return ui_text


