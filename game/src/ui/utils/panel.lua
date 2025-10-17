---@class Panel
---@field image love.Image
---@field quads table
---@field sliceSize number
local Panel = {}

-- Initialize the panel system
function Panel.init()
    -- Load the panel sprite
    Panel.image = love.graphics.newImage("resources/ui/panel-000.png")
    -- Set to nearest filtering for crisp pixel art scaling (no blur)
    Panel.image:setFilter("nearest", "nearest")
    Panel.sliceSize = 16 -- Each slice is 16x16 pixels in the source image (48/3)

    -- Create quads for 9-slice rendering
    -- Layout:
    -- [TL] [T ] [TR]
    -- [L ] [C ] [R ]
    -- [BL] [B ] [BR]

    local s = Panel.sliceSize
    Panel.quads = {
        topLeft     = love.graphics.newQuad(0,     0,     s, s, 48, 48),
        top         = love.graphics.newQuad(s,     0,     s, s, 48, 48),
        topRight    = love.graphics.newQuad(s * 2, 0,     s, s, 48, 48),
        left        = love.graphics.newQuad(0,     s,     s, s, 48, 48),
        center      = love.graphics.newQuad(s,     s,     s, s, 48, 48),
        right       = love.graphics.newQuad(s * 2, s,     s, s, 48, 48),
        bottomLeft  = love.graphics.newQuad(0,     s * 2, s, s, 48, 48),
        bottom      = love.graphics.newQuad(s,     s * 2, s, s, 48, 48),
        bottomRight = love.graphics.newQuad(s * 2, s * 2, s, s, 48, 48),
    }
end

---Draw a 9-slice panel at the specified position and size
---@param x number X position
---@param y number Y position
---@param width number Total width of the panel
---@param height number Total height of the panel
---@param alpha number|nil Alpha transparency (0-1), defaults to 1.0
---@param color table|nil Color tint {r, g, b} (0-1), defaults to {1, 1, 1} (white/no tint)
function Panel.draw(x, y, width, height, alpha, color)
    if not Panel.image then
        Panel.init()
    end

    alpha = alpha or 1.0
    color = color or {0.1, 0.1, 0.1}

    -- Save current color
    local r, g, b, a = love.graphics.getColor()
    love.graphics.setColor(color[1], color[2], color[3], alpha)

    local s = Panel.sliceSize  -- 16px

    -- Calculate dimensions for the stretchable parts
    local centerWidth = width - (s * 2)
    local centerHeight = height - (s * 2)

    -- Ensure minimum size
    if centerWidth < 0 then centerWidth = 0 end
    if centerHeight < 0 then centerHeight = 0 end

    -- Calculate scale factors for edges and center
    local scaleX = centerWidth / s  -- How much to stretch horizontally
    local scaleY = centerHeight / s  -- How much to stretch vertically

    -- Draw corners (no scaling)
    love.graphics.draw(Panel.image, Panel.quads.topLeft, x, y)
    love.graphics.draw(Panel.image, Panel.quads.topRight, x + width - s, y)
    love.graphics.draw(Panel.image, Panel.quads.bottomLeft, x, y + height - s)
    love.graphics.draw(Panel.image, Panel.quads.bottomRight, x + width - s, y + height - s)

    -- Draw edges (stretched to fill the gap between corners)
    if centerWidth > 0 then
        -- Top and bottom edges: stretch horizontally
        love.graphics.draw(Panel.image, Panel.quads.top, x + s, y, 0, scaleX, 1)
        love.graphics.draw(Panel.image, Panel.quads.bottom, x + s, y + height - s, 0, scaleX, 1)
    end

    if centerHeight > 0 then
        -- Left and right edges: stretch vertically
        love.graphics.draw(Panel.image, Panel.quads.left, x, y + s, 0, 1, scaleY)
        love.graphics.draw(Panel.image, Panel.quads.right, x + width - s, y + s, 0, 1, scaleY)
    end

    -- Draw center (scaled to fill remaining space)
    if centerWidth > 0 and centerHeight > 0 then
        love.graphics.draw(Panel.image, Panel.quads.center, x + s, y + s, 0, scaleX, scaleY)
    end

    -- Restore color
    love.graphics.setColor(r, g, b, a)
end

return Panel

