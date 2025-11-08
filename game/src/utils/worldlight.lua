local CustomLightRenderer = require("src.utils.CustomLightRenderer")

local initialized = false
local lastWidth = nil
local lastHeight = nil

local M = {}

function M.init(canvasWidth, canvasHeight)
  if initialized then return CustomLightRenderer end

  -- Initialize CustomLightRenderer with pixel canvas dimensions
  canvasWidth = canvasWidth or love.graphics.getWidth()
  canvasHeight = canvasHeight or love.graphics.getHeight()
  lastWidth, lastHeight = canvasWidth, canvasHeight
  CustomLightRenderer.init(canvasWidth, canvasHeight)

  initialized = true
  return CustomLightRenderer
end

function M.get()
  if not initialized then
    M.init(lastWidth, lastHeight)
  end
  return CustomLightRenderer
end

function M.setAmbientColor(r, g, b, a, duration)
  CustomLightRenderer.setAmbientColor(r, g, b, a, duration)
end

function M.update(dt, camera)
  if not initialized then return end

  CustomLightRenderer.update(dt, camera)
end

function M.cleanup()
  if not initialized then return end

  -- Cleanup CustomLightRenderer
  CustomLightRenderer.cleanup()
  initialized = false
  -- Preserve last known dimensions so we can reinitialize lazily on demand
end

return M
