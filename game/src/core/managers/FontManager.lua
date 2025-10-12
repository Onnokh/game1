local FontManager = {}

local cache = {}

---Get a font by path and size, with caching
---@param path string
---@param size number
---@return love.Font
function FontManager.get(path, size)
    local key = path .. ":" .. tostring(size)
    if cache[key] then
        return cache[key]
    end
    local font = love.graphics.newFont(path, size)
    if font and font.setFilter then
        font:setFilter('nearest', 'nearest')
    end
    cache[key] = font
    return font
end

---Convenience getter for the determination font
---@param size number
---@return love.Font
function FontManager.getDetermination(size)
    return FontManager.get("resources/font/determination.ttf", size)
end

return FontManager


