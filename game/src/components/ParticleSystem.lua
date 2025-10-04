---@class ParticleSystem
---@field particles table Array of active particles
---@field maxParticles number Maximum number of particles
---@field enabled boolean Whether the particle system is enabled
---@field gravity number Gravity affecting particles
---@field wind number Wind affecting particles
---@field activeCount number Number of currently active particles
local ParticleSystem = {}
ParticleSystem.__index = ParticleSystem

---Create a new ParticleSystem component
---@param maxParticles number|nil Maximum number of particles
---@param gravity number|nil Gravity affecting particles
---@param wind number|nil Wind affecting particles
---@return Component|ParticleSystem
function ParticleSystem.new(maxParticles, gravity, wind)
    local Component = require("src.core.Component")
    local self = setmetatable(Component.new("ParticleSystem"), ParticleSystem)

    self.maxParticles = maxParticles or 100
    self.enabled = true
    self.gravity = gravity or 0
    self.wind = wind or 0
    self.activeCount = 0

    -- Pre-allocate particle pool for better performance
    self.particles = {}
    for i = 1, self.maxParticles do
        self.particles[i] = {
            active = false,
            x = 0, y = 0,
            vx = 0, vy = 0,
            life = 0, maxLife = 0,
            r = 1, g = 1, b = 1, a = 1,
            size = 2,
            fade = true
        }
    end

    return self
end

---Add a particle to the system
---@param x number X position
---@param y number Y position
---@param vx number X velocity
---@param vy number Y velocity
---@param life number Life time in seconds
---@param color table|nil Color table with r, g, b, a
---@param size number|nil Particle size
---@param fade boolean|nil Whether particle fades over time
function ParticleSystem:addParticle(x, y, vx, vy, life, color, size, fade)
    if not self.enabled or self.activeCount >= self.maxParticles then
        return
    end

    -- Find an inactive particle to reuse
    for i = 1, self.maxParticles do
        local particle = self.particles[i]
        if not particle.active then
            particle.active = true
            particle.x = x
            particle.y = y
            particle.vx = vx
            particle.vy = vy
            particle.life = life
            particle.maxLife = life
            particle.size = size or 2
            particle.fade = fade ~= false -- Default to true

            -- Set color (Love2D uses 0-1 range)
            if color then
                particle.r = color.r or 1
                particle.g = color.g or 1
                particle.b = color.b or 1
                particle.a = color.a or 1
            else
                particle.r = 1
                particle.g = 1
                particle.b = 1
                particle.a = 1
            end

            self.activeCount = self.activeCount + 1
            break
        end
    end
end

---Update all particles
---@param dt number Delta time
function ParticleSystem:update(dt)
    if not self.enabled then
        return
    end

    for i = 1, self.maxParticles do
        local particle = self.particles[i]

        if particle.active then
            -- Update position
            particle.x = particle.x + particle.vx * dt
            particle.y = particle.y + particle.vy * dt

            -- Apply gravity and wind
            particle.vy = particle.vy + self.gravity * dt
            particle.vx = particle.vx + self.wind * dt

            -- Update life
            particle.life = particle.life - dt

            -- Deactivate dead particles instead of removing them
            if particle.life <= 0 then
                particle.active = false
                self.activeCount = self.activeCount - 1
            end
        end
    end
end

---Draw all particles
function ParticleSystem:draw()
    if not self.enabled or self.activeCount == 0 then
        return
    end

    -- Store current color to restore later
    local r, g, b, a = love.graphics.getColor()

    for i = 1, self.maxParticles do
        local particle = self.particles[i]

        if particle.active then
            -- Calculate alpha based on life if fading
            local alpha = particle.a
            if particle.fade then
                alpha = particle.a * (particle.life / particle.maxLife)
            end

            -- Set color (Love2D uses 0-1 range)
            love.graphics.setColor(particle.r, particle.g, particle.b, alpha)

            -- Draw particle as a circle (more efficient than rectangle for small particles)
            love.graphics.circle("fill", particle.x, particle.y, particle.size)
        end
    end

    -- Restore original color
    love.graphics.setColor(r, g, b, a)
end

---Clear all particles
function ParticleSystem:clear()
    for i = 1, self.maxParticles do
        self.particles[i].active = false
    end
    self.activeCount = 0
end

---Set the maximum number of particles
---@param maxParticles number New maximum
function ParticleSystem:setMaxParticles(maxParticles)
    local newMax = math.max(0, maxParticles)
    if newMax ~= self.maxParticles then
        -- Resize particle pool if needed
        if newMax > self.maxParticles then
            -- Add new particles
            for i = self.maxParticles + 1, newMax do
                self.particles[i] = {
                    active = false,
                    x = 0, y = 0,
                    vx = 0, vy = 0,
                    life = 0, maxLife = 0,
                    r = 1, g = 1, b = 1, a = 1,
                    size = 2,
                    fade = true
                }
            end
        end
        self.maxParticles = newMax
    end
end

---Enable or disable the particle system
---@param enabled boolean Whether to enable the system
function ParticleSystem:setEnabled(enabled)
    self.enabled = enabled
end

---Get the number of active particles
---@return number Number of active particles
function ParticleSystem:getParticleCount()
    return self.activeCount
end

---Create a burst of particles in a circle
---@param x number Center X position
---@param y number Center Y position
---@param radius number Radius of the burst
---@param count number Number of particles to create
---@param life number Life time of particles
---@param color table|nil Color of particles
---@param size number|nil Size of particles
function ParticleSystem:createBurst(x, y, radius, count, life, color, size)
    for i = 1, count do
        local angle = (i / count) * math.pi * 2
        local distance = math.random() * radius
        local px = x + math.cos(angle) * distance
        local py = y + math.sin(angle) * distance

        local speed = 50 + math.random() * 100
        local vx = math.cos(angle) * speed
        local vy = math.sin(angle) * speed

        self:addParticle(px, py, vx, vy, life, color, size)
    end
end

---Create particles in a line (for slashes, etc.)
---@param x1 number Start X position
---@param y1 number Start Y position
---@param x2 number End X position
---@param y2 number End Y position
---@param count number Number of particles to create
---@param life number Life time of particles
---@param color table|nil Color of particles
---@param size number|nil Size of particles
function ParticleSystem:createLine(x1, y1, x2, y2, count, life, color, size)
    for i = 1, count do
        local t = (i - 1) / (count - 1)
        local px = x1 + (x2 - x1) * t
        local py = y1 + (y2 - y1) * t

        local vx = (math.random() - 0.5) * 100
        local vy = (math.random() - 0.5) * 100

        self:addParticle(px, py, vx, vy, life, color, size)
    end
end

return ParticleSystem
