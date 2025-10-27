local PixelRenderer = {}

-- Module state
local initialized = false
local canvas = nil
local baseWidth = 320
local baseHeight = 180
local scale = 1

-- Initialize the pixel renderer
function PixelRenderer.init(width, height)
    if initialized then
        print("[PixelRenderer] Already initialized, recreating canvas...")
        if canvas then
            canvas:release()
        end
    end

    baseWidth = width or baseWidth
    baseHeight = height or baseHeight

    -- Calculate scale factor based on current window size
    local screenW, screenH = love.graphics.getDimensions()
    scale = math.floor(math.min(screenW / baseWidth, screenH / baseHeight))

    print("[PixelRenderer] Initializing with base resolution:", baseWidth, "x", baseHeight, "scale:", scale)

    -- Create low-res canvas
    canvas = love.graphics.newCanvas(baseWidth, baseHeight)
    if not canvas then
        error("Failed to create pixel canvas")
    end

    -- Set nearest-neighbor filtering for crisp pixels
    canvas:setFilter("nearest", "nearest")

    initialized = true
    print("[PixelRenderer] Initialized successfully")
end

-- Get the pixel-perfect canvas for shader use
function PixelRenderer.getCanvas()
    return canvas
end

-- Get the current scale factor
function PixelRenderer.getScale()
    return scale
end

-- Get base dimensions
function PixelRenderer.getBaseDimensions()
    return baseWidth, baseHeight
end

-- Begin drawing to the pixel canvas
function PixelRenderer.begin()
    if not initialized or not canvas then
        error("PixelRenderer not initialized. Call PixelRenderer.init() first.")
    end

    -- Switch to pixel canvas
    love.graphics.setCanvas(canvas)

    -- Clear canvas
    love.graphics.clear(0, 0, 0, 1)
end

-- End drawing to pixel canvas and draw scaled to screen
function PixelRenderer.finish()
    if not initialized or not canvas then
        return
    end

    -- Switch back to screen
    love.graphics.setCanvas()

    -- Get screen dimensions
    local screenW, screenH = love.graphics.getDimensions()

    -- Update scale based on current screen size
    scale = math.floor(math.min(screenW / baseWidth, screenH / baseHeight))
end

-- Handle window resize (call this from love.resize if needed)
function PixelRenderer.handleResize()
    if not initialized then return end

    -- Update scale
    local screenW, screenH = love.graphics.getDimensions()
    scale = math.floor(math.min(screenW / baseWidth, screenH / baseHeight))
end

-- Cleanup
function PixelRenderer.cleanup()
    if initialized and canvas then
        canvas:release()
        canvas = nil
        initialized = false
    end
end

return PixelRenderer

