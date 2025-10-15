local System = require("src.core.System")
---@class FootprintsSystem : System
---@field name string
---@field _prints table<string, any>
---@field _printOrder table
---@field _globalMax number
local FootprintsSystem = System:extend("FootprintsSystem", {})

local FootprintsEmitter = require("src.components.FootprintsEmitter")
local Footprint = require("src.components.Footprint")

-- Render below sprites, above tilemap similar to GroundShadowSystem
FootprintsSystem.drawOrder = -10

function FootprintsSystem.new()
    local self = System.new()
    setmetatable(self, FootprintsSystem)
    -- This system does not use requiredComponents; it scans all entities for emitters
    self.name = "FootprintsSystem"
    self._prints = {}
    self._printOrder = {} -- queue of keys for FIFO removal when capped
    self._globalMax = 600 -- global cap across all emitters
    return self
end

local function distance(dx, dy)
    return math.sqrt(dx * dx + dy * dy)
end

local function perp(dx, dy)
    -- Perpendicular vector (left-hand)
    return -dy, dx
end

function FootprintsSystem:update(dt)
    if not self.world then return end

    -- Age and cull prints
    for key, fp in pairs(self._prints) do
        fp.age = fp.age + dt
        if fp.age >= fp.lifetime then
            self._prints[key] = nil
        end
    end

    -- Compact order list removing missing keys
    do
        local i = 1
        while i <= #self._printOrder do
            local k = self._printOrder[i]
            if not self._prints[k] then
                table.remove(self._printOrder, i)
            else
                i = i + 1
            end
        end
    end

    -- Iterate all entities to process emitters
    for _, entity in ipairs(self.world.entities) do
        if entity.active then
            local emitter = entity:getComponent("FootprintsEmitter")
            if emitter then
                -- Optional pause via StateMachine state name
                if emitter.pausedByStates and #emitter.pausedByStates > 0 then
                    local sm = entity:getComponent("StateMachine")
                    if sm then
                        local cur = sm:getCurrentState()
                        for _, paused in ipairs(emitter.pausedByStates) do
                            if cur == paused then
                                -- Pause emission but keep last position updated; do not touch accumulators
                                local baseX, baseY = nil, nil
                                local pfc = entity:getComponent("PathfindingCollision")
                                if pfc then
                                    baseX, baseY = pfc:getCenterPosition()
                                    local yNudge = math.max(4, (pfc.height or 0) * 0.15)
                                    baseY = baseY + yNudge
                                end
                                local pos = entity:getComponent("Position")
                                if pos then emitter:resetTracking(baseX or pos.x, baseY or pos.y) end
                                goto continue_entity
                            end
                        end
                    end
                end

                -- Base position from PathfindingCollision center if available, else Position
                local baseX, baseY = nil, nil
                do
                    local pfc = entity:getComponent("PathfindingCollision")
                    if pfc then
                        baseX, baseY = pfc:getCenterPosition()
                        local yNudge = math.max(4, (pfc.height or 0) * 0.15)
                        baseY = baseY + yNudge
                    end
                end
                local pos = entity:getComponent("Position")
                if pos then
                    local x = baseX or pos.x
                    local y = baseY or pos.y
                    if not emitter._lastX then
                        emitter._lastX, emitter._lastY = x, y
                    end
                    local dx = x - emitter._lastX
                    local dy = y - emitter._lastY
                    local moved = distance(dx, dy)

                    if moved > 0.1 then
                        local ndx, ndy = dx / moved, dy / moved
                        local px, py = perp(ndx, ndy)

                        -- Advance accumulators and emit when threshold reached
                        for i, limb in ipairs(emitter.limbs) do
                            emitter._accumulators[i] = (emitter._accumulators[i] or 0) + moved
                            local target = (emitter._nextSpacing and emitter._nextSpacing[i]) or emitter.spacing
                            while emitter._accumulators[i] >= target do
                                emitter._accumulators[i] = emitter._accumulators[i] - target

                                -- Spawn footprint for this limb
                                local lateral = limb.lateral or 0
                                local fx = x + px * lateral
                                local fy = y + py * lateral
                                local angle = math.atan2(ndy, ndx)

                                -- Size relative to pathfinding collider if available
                                local width = 10
                                local height = 5
                                do
                                    local pfc = entity:getComponent("PathfindingCollision")
                                    if pfc then
                                        -- Halved previous sizing for a subtler footprint
                                        width = math.max(1, (pfc.width or width) * 0.250)
                                        height = math.max(1, (pfc.height or height) * 0.175)
                                    end
                                end
                                -- Tiny randomness: scale and rotation jitter
                                local scale = 0.9 + (math.random()) * 0.2 -- 0.9..1.1
                                width = width * scale
                                height = height * scale
                                local angleJitter = (math.random() * 2 - 1) * (math.pi / 30) -- ±6°
                                angle = angle + angleJitter

                                local fp = Footprint.new(fx, fy, angle, emitter.lifetime, width, height, emitter.baseAlpha)

                                -- Store with unique key
                                local key = tostring(fp):gsub("table: ", "") .. tostring(love.timer.getTime())
                                self._prints[key] = fp
                                table.insert(self._printOrder, key)

                                -- Enforce caps
                                while #self._printOrder > self._globalMax do
                                    local oldestKey = table.remove(self._printOrder, 1)
                                    self._prints[oldestKey] = nil
                                end

                                -- Pick next spacing target with jitter (±10%)
                                if emitter._nextSpacing then
                                    -- Next spacing is at least base spacing (slightly larger)
                                    emitter._nextSpacing[i] = emitter.spacing * (1.05 + (math.random()) * 0.20)
                                end
                            end
                        end
                    end

                    emitter._lastX, emitter._lastY = x, y
                end
            end
        end
        ::continue_entity::
    end
end

function FootprintsSystem:draw()
    if not next(self._prints) then return end
    -- Render as dark ovals with alpha fade
    local lg = love.graphics
    local r, g, b, a = lg.getColor()
    for _, fp in pairs(self._prints) do
        local t = math.min(1, fp.age / fp.lifetime)
        local alpha = fp.baseAlpha * (1 - t) * (1 - t)
        if alpha > 0.01 then
            lg.push()
            lg.translate(fp.x, fp.y)
            lg.rotate(fp.angle)
            lg.setColor(0, 0, 0, alpha)
            lg.ellipse("fill", 0, 0, fp.width, fp.height)
            lg.pop()
        end
    end
    lg.setColor(r, g, b, a)
end

return FootprintsSystem


