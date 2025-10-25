local System = require("src.core.System")

---@class CollisionSystem : System
---@field physicsWorld love.World|nil
local CollisionSystem = System:extend("CollisionSystem", {"Position"})

---Initialize physics callbacks when world is set
function CollisionSystem:setWorld(world)
    System.setWorld(self, world) -- Call parent setWorld
    -- Cache physics world reference for convenience
    self.physicsWorld = world and world.physicsWorld or nil
    if self.world and self.physicsWorld then
        self.physicsWorld:setCallbacks(
            function(a, b, contact)
                -- beginContact
                local ua = a and a:getUserData() or nil
                local ub = b and b:getUserData() or nil

                -- Handle attack collisions
                local function handle(attackFixture, otherFixture)
                    if not attackFixture then return end
                    local u = attackFixture:getUserData()
                    if u and type(u) == "table" and u.kind == "attack" and u.component then
                        local attackComp = u.component
                        local otherU = otherFixture and otherFixture:getUserData() or nil
                        local otherEntity = nil
                        if otherU and type(otherU) == "table" and otherU.entity then
                            otherEntity = otherU.entity
                        end
                        if otherEntity and otherEntity ~= attackComp.attacker and not attackComp.hitEntities[otherEntity.id] then
                            -- Check for friendly fire prevention
                            local attackerIsMonster = attackComp.attacker and attackComp.attacker:hasTag("Monster")
                            local targetIsMonster = otherEntity:hasTag("Monster")

                            -- Prevent monster vs monster damage (friendly fire)
                            if attackerIsMonster and targetIsMonster then
                                return -- Skip damage for monster vs monster
                            end

                            -- Enqueue damage
                            local DamageQueue = require("src.DamageQueue")
                            DamageQueue:push(otherEntity, attackComp.damage, attackComp.attacker, "physical", attackComp.knockback, nil)
                            attackComp.hitEntities[otherEntity.id] = true
                        end
                    end
                end
                if ua and type(ua) == "table" and ua.kind == "attack" then handle(a, b) end
                if ub and type(ub) == "table" and ub.kind == "attack" then handle(b, a) end

                -- Handle trigger zone collisions
                local function handleTrigger(triggerFixture, otherFixture)
                    if not triggerFixture then return end
                    local u = triggerFixture:getUserData()
                    if u and type(u) == "table" and u.kind == "trigger" and u.component then
                        local triggerZone = u.component
                        local otherU = otherFixture and otherFixture:getUserData() or nil
                        local otherEntity = nil
                        if otherU and type(otherU) == "table" and otherU.entity then
                            otherEntity = otherU.entity
                        end
                        if otherEntity then
                            triggerZone:addEntityInside(otherEntity)
                        end
                    end
                end
                if ua and type(ua) == "table" and ua.kind == "trigger" then handleTrigger(a, b) end
                if ub and type(ub) == "table" and ub.kind == "trigger" then handleTrigger(b, a) end

                -- Handle bullet collisions
                local function handleBullet(bulletFixture, otherFixture)
                    if not bulletFixture then return end
                    local u = bulletFixture:getUserData()
                    if u and type(u) == "table" and u.kind == "bullet" and u.entity then
                        local bulletEntity = u.entity
                        local bulletComp = bulletEntity:getComponent("Bullet")
                        if not bulletComp then return end

                        -- Check if hitting an entity first
                        local otherU = otherFixture:getUserData()
                        if otherU and type(otherU) == "table" and otherU.entity then
                            local otherEntity = otherU.entity
                            -- Don't hit owner or already-hit entities
                            if otherEntity.id ~= (bulletComp.owner and bulletComp.owner.id or -1)
                               and not bulletComp:hasHitEntity(otherEntity.id) then
                                -- Mark for damage (will be handled by BulletSystem)
                                if not bulletEntity._hitEntities then
                                    bulletEntity._hitEntities = {}
                                end
                                table.insert(bulletEntity._hitEntities, otherEntity)
                            end
                        else
                            -- Only treat as static wall if it's NOT an entity
                            local otherBody = otherFixture:getBody()
                            if otherBody and otherBody:getType() == "static" then
                                -- Mark bullet for removal (will be handled by BulletSystem)
                                bulletEntity._hitStatic = true
                                return
                            end
                        end
                    end
                end
                if ua and type(ua) == "table" and ua.kind == "bullet" then handleBullet(a, b) end
                if ub and type(ub) == "table" and ub.kind == "bullet" then handleBullet(b, a) end

            end,
            function(a, b, contact)
                -- endContact
                local ua = a and a:getUserData() or nil
                local ub = b and b:getUserData() or nil

                -- Handle trigger zone exits
                local function handleTriggerExit(triggerFixture, otherFixture)
                    if not triggerFixture then return end
                    local u = triggerFixture:getUserData()
                    if u and type(u) == "table" and u.kind == "trigger" and u.component then
                        local triggerZone = u.component
                        local otherU = otherFixture and otherFixture:getUserData() or nil
                        local otherEntity = nil
                        if otherU and type(otherU) == "table" and otherU.entity then
                            otherEntity = otherU.entity
                        end
                        if otherEntity then
                            triggerZone:removeEntityInside(otherEntity)
                        end
                    end
                end
                if ua and type(ua) == "table" and ua.kind == "trigger" then handleTriggerExit(a, b) end
                if ub and type(ub) == "table" and ub.kind == "trigger" then handleTriggerExit(b, a) end
            end, -- endContact
            function() end, -- preSolve
            function() end  -- postSolve
        )
    end
end

---On update, ensure colliders exist for entities lacking one
---@param dt number
function CollisionSystem:update(dt)
	if not self.world or not self.physicsWorld then return end
	if not self or not self.entities then return end
	for _, entity in ipairs(self.entities) do
		local position = entity:getComponent("Position")
		local movement = entity:getComponent("Movement")
		local knockback = entity:getComponent("Knockback")
		if position and self.world and self.physicsWorld then
			-- Handle PathfindingCollision component (for pathfinding and physics collision)
			local pathfindingCollision = entity:getComponent("PathfindingCollision")
			if pathfindingCollision then
				if not pathfindingCollision:hasCollider() then
					pathfindingCollision:createCollider(self.physicsWorld, position.x, position.y)
				end
				-- Tag fixture with entity reference for contact handlers (for both new and existing colliders)
				if pathfindingCollision.collider and pathfindingCollision.collider.fixture then
					pathfindingCollision.collider.fixture:setUserData({ kind = "entity", entity = entity })
				end
			end

			-- Handle PhysicsCollision component (for physics only)
			local physicsCollision = entity:getComponent("PhysicsCollision")
			if physicsCollision and not physicsCollision:hasCollider() then
				physicsCollision:createCollider(self.physicsWorld, position.x, position.y)
				-- Tag fixture with entity reference for contact handlers
				-- Only set if not already set (e.g., bullets set their own userData)
				if physicsCollision.collider and physicsCollision.collider.fixture then
					local existingData = physicsCollision.collider.fixture:getUserData()
					if not existingData then
						physicsCollision.collider.fixture:setUserData({ kind = "entity", entity = entity })
					end
				end
			end

			-- Update knockback timer and remove when expired
			if knockback and knockback.active then
				knockback.timer = (knockback.timer or 0) + dt
				if knockback.timer >= (knockback.duration or 0.1) then
					knockback.active = false
				end
			end

			-- Apply movement velocity to collider and sync back ECS position
			if movement then
				if pathfindingCollision and pathfindingCollision:hasCollider() and pathfindingCollision.type ~= "static" then
					-- During knockback, let physics impulse drive motion; don't override
					if not (knockback and knockback.active) then
						pathfindingCollision:setLinearVelocity(movement.velocityX, movement.velocityY)
					end
					local x, y = pathfindingCollision:getPosition()
					position:setPosition(x, y)
				end

				local physicsCollision = entity:getComponent("PhysicsCollision")
				if physicsCollision and physicsCollision:hasCollider() then
					physicsCollision:setPosition(position.x, position.y)
					-- Only set userData if not already set (e.g., bullets set their own)
					if physicsCollision.collider and physicsCollision.collider.fixture then
						local existingData = physicsCollision.collider.fixture:getUserData()
						if not existingData then
							physicsCollision.collider.fixture:setUserData({ kind = "entity", entity = entity })
						end
					end
				end
			end
		end
	end
end

return CollisionSystem


