local LightWorld = require "shadows.LightWorld"

local lw = nil
local ambient = { r = 70, g = 90, b = 140, a = 255 }
local tween = {
  active = false,
  start = { r = 70, g = 90, b = 140, a = 255 },
  target = { r = 70, g = 90, b = 140, a = 255 },
  elapsed = 0,
  duration = 0
}

local M = {}

function M.init()
  if lw then return lw end
  lw = LightWorld:new()
  lw:SetColor(ambient.r, ambient.g, ambient.b, ambient.a)
  return lw
end

function M.get()
  return lw
end

function M.setAmbientColor(r, g, b, a, duration)
  local targetA = a or 255
  if duration and duration > 0 and lw then
    tween.active = true
    tween.start.r, tween.start.g, tween.start.b, tween.start.a = ambient.r, ambient.g, ambient.b, ambient.a
    tween.target.r, tween.target.g, tween.target.b, tween.target.a = r, g, b, targetA
    tween.elapsed = 0
    tween.duration = duration
  else
    ambient.r, ambient.g, ambient.b, ambient.a = r, g, b, targetA
    if lw and lw.SetColor then lw:SetColor(ambient.r, ambient.g, ambient.b, ambient.a) end
    tween.active, tween.elapsed, tween.duration = false, 0, 0
  end
end

function M.update(dt, camera)
  if not lw or not camera then return end
  if tween.active then
    tween.elapsed = tween.elapsed + dt
    local d = tween.duration > 0 and tween.duration or 0
    local u = d > 0 and math.min(1, tween.elapsed / d) or 1
    local function lerp(a, b, k) return a + (b - a) * k end
    ambient.r = lerp(tween.start.r, tween.target.r, u)
    ambient.g = lerp(tween.start.g, tween.target.g, u)
    ambient.b = lerp(tween.start.b, tween.target.b, u)
    ambient.a = lerp(tween.start.a, tween.target.a, u)
    lw:SetColor(ambient.r, ambient.g, ambient.b, ambient.a)
    if u >= 1 then tween.active = false end
  end

  local camX, camY, scale = camera.x, camera.y, camera.scale
  local halfW, halfH = love.graphics.getWidth() / 2, love.graphics.getHeight() / 2
  lw:SetPosition(camX - (halfW / scale), camY - (halfH / scale), scale)
  lw:Update()
end

function M.cleanup()
  if not lw then return end
  if lw.Lights then
    for _, light in pairs(lw.Lights) do if light and light.Remove then light:Remove() end end
  end
  if lw.Canvas then lw.Canvas:release() end
  lw = nil
end

return M


