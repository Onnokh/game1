local System = require("src.core.System")

---@class AttackColliderSystem : System
local AttackColliderSystem = System:extend("AttackColliderSystem", {"AttackCollider"})

---Update all ephemeral attack colliders and clean up expired ones
---@param dt number Delta time
function AttackColliderSystem:update(dt)
    for _, entity in ipairs(self.entities) do
        local ac = entity:getComponent("AttackCollider")
        if ac then
            if ac.update then ac:update(dt) end
            if ac.isExpired and ac:isExpired() then
                if ac.destroy then ac:destroy() end
                entity:removeComponent("AttackCollider")
            end
        end
    end
end

---Draw debug rectangles for attack colliders
function AttackColliderSystem:draw()
    for _, entity in ipairs(self.entities) do
        local ac = entity:getComponent("AttackCollider")
        if ac and ac.collider and ac.collider.body then
            local body = ac.collider.body
            local x, y = body:getPosition()

            -- Get the fixture to get the shape dimensions
            local fixture = ac.collider.fixture
            if fixture then
                local shape = fixture:getShape()
                local shapeType = shape:getType()

                -- Set red color for attack colliders
                love.graphics.setColor(1, 0, 0, 0.5) -- Red with 50% transparency

                if shapeType == "rectangle" then
                    local w, h = shape:getDimensions()
                    love.graphics.rectangle("fill", x - w/2, y - h/2, w, h)
                    love.graphics.setColor(1, 0, 0, 1) -- Solid red outline
                    love.graphics.rectangle("line", x - w/2, y - h/2, w, h)
                elseif shapeType == "circle" then
                    local radius = shape:getRadius()
                    love.graphics.circle("fill", x, y, radius)
                    love.graphics.setColor(1, 0, 0, 1) -- Solid red outline
                    love.graphics.circle("line", x, y, radius)
                end
            end
        end
    end


    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end

return AttackColliderSystem


