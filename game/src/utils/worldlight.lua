local luven = require "lib.luven.luven"

local initialized = false
local ambient = { r = 1.0, g = 0.94, b = 1.0, a = 1.0 } -- Default: bright (0-1 range for Luven)
local tween = {
  active = false,
  start = { r = 1.0, g = 0.94, b = 1.0, a = 1.0 },
  target = { r = 1.0, g = 0.94, b = 1.0, a = 1.0 },
  elapsed = 0,
  duration = 0
}

local M = {}

function M.init()
  if initialized then return luven end

  -- Initialize Luven with screen dimensions, and disable integrated camera (we use our own)
  local screenWidth = love.graphics.getWidth()
  local screenHeight = love.graphics.getHeight()
  luven.init(screenWidth, screenHeight, false) -- false = don't use Luven's camera

  -- Set initial ambient color
  luven.setAmbientLightColor({ ambient.r, ambient.g, ambient.b, ambient.a })

  initialized = true
  return luven
end

function M.get()
  return luven
end

function M.setAmbientColor(r, g, b, a, duration)
  -- Convert from 0-255 range to 0-1 range for Luven
  local targetR = r / 255
  local targetG = g / 255
  local targetB = b / 255
  local targetA = (a or 255) / 255

  if duration and duration > 0 and initialized then
    tween.active = true
    tween.start.r, tween.start.g, tween.start.b, tween.start.a = ambient.r, ambient.g, ambient.b, ambient.a
    tween.target.r, tween.target.g, tween.target.b, tween.target.a = targetR, targetG, targetB, targetA
    tween.elapsed = 0
    tween.duration = duration
  else
    ambient.r, ambient.g, ambient.b, ambient.a = targetR, targetG, targetB, targetA
    if initialized then
      luven.setAmbientLightColor({ ambient.r, ambient.g, ambient.b, ambient.a })
    end
    tween.active, tween.elapsed, tween.duration = false, 0, 0
  end
end

function M.update(dt, camera)
  if not initialized then return end

  -- Handle ambient color tweening
  if tween.active then
    tween.elapsed = tween.elapsed + dt
    local d = tween.duration > 0 and tween.duration or 0
    local u = d > 0 and math.min(1, tween.elapsed / d) or 1
    local function lerp(a, b, k) return a + (b - a) * k end
    ambient.r = lerp(tween.start.r, tween.target.r, u)
    ambient.g = lerp(tween.start.g, tween.target.g, u)
    ambient.b = lerp(tween.start.b, tween.target.b, u)
    ambient.a = lerp(tween.start.a, tween.target.a, u)
    luven.setAmbientLightColor({ ambient.r, ambient.g, ambient.b, ambient.a })
    if u >= 1 then tween.active = false end
  end

  -- Update Luven (for flickering lights, etc.)
  luven.update(dt)
end

function M.cleanup()
  if not initialized then return end

  -- Dispose of Luven (removes all lights and releases canvases)
  luven.dispose()
  initialized = false
end

return M
