function newEntity()
    local entity = {}
    
    entity.i, entity.j = nil        -- board coordinates
    entity.x, entity.y = 0, 0       -- screen coordinates (can varies from linear interpolation of coordinates during animations)
    entity.snappingSpeed = 30 * tileSize
    entity.w, entity.h = tileSize, tileSize
    entity.blockPath = true         --does entity prevent from walking on his cell

    entity.updates = {
        function (self, dt)
            local x, y = gridToScreen(self.i, self.j)
            if x ~= self.x or y ~= self.y then
                local maxDistance = self.snappingSpeed * dt
                local ndx, ndy, d = math.normalize(self.x - x, self.y - y)
                if d <= maxDistance then
                    self.x, self.y = x, y
                else
                    self.x, self.y = self.x-ndx*self.snappingSpeed*dt, self.y - ndy * self.snappingSpeed*dt
                end
            end
        end
    }
    entity.update = function (self, dt)
        for u, updateFunction in pairs(self.updates) do
            updateFunction(self, dt)
        end
    end
    
    entity.move = function(self, newI, newJ)
        if not map[newI] or not map[newI][newJ] or map[newI][newJ]  < 1 then return false end
        local entityOnNewPos = getEntityOn(newI, newJ)
        if not entityOnNewPos or not entityOnNewPos.blockPath then
            self.i, self.j = newI, newJ
            return true
        end
        return false
    end
    
    entity.onNewTurn = function () end
    
    entity.draw = function (self)
        love.graphics.setColor(self.color or {.8, 0, .8})
        love.graphics.translate(self.x, self.y)
        love.graphics.circle("fill", 0, 0, 16)
    end
    
    entity.snapToGrid = function (self)
        self.x, self.y = gridToScreen(self.i, self.j)
    end
    
    entity.loadAnimation = function (self, spriteSet)
        if self.spriteSet then
            self.animation = newAnimation(love.graphics.newImage(self.spriteSet.path or spriteSet.path or spriteSet),
            self.spriteSet.width or spriteSet.width or 16, self.spriteSet.height or spriteSet.height or 16, 1, 32, 32)
        end
        if self.animation then
            self.draw = function (self)
                love.graphics.setColor(self.color or {1, 1, 1})
                love.graphics.translate(self.x+.5*zoomX*tileSize, self.y+.5*zoomY*tileSize-.5*self.h)
                if self:isDead() then
                    love.graphics.rotate(math.rad(-90))
                end
                self.animation:draw()
            end
            table.insert(self.updates,
                function (self, dt)
                    self.animation:update(dt)
                end
            )
        end
    end
    
    entity.initEntity = function (self)
        self:loadAnimation()
        if self.i and self.j then
            self:snapToGrid()
        end
    end

    table.insert(entities, entity)
    return entity
end

function newLivingEntity(entity)
    local entity = entity or newEntity()

    entity.ressources = {}
    entity.isAvailable = function (self, ressource)
        local name = ressource.name
        if self.ressources[name] then
            return self.ressources[name].quantity >= ressource.quantity
        end
        return false
    end
    entity.credit = function (self, ressource)
        if ressource.quantity < 0 then return end
        local name = ressource.name
        local selfRessource = self.ressources[name]
        if self.ressources[name] then
            if selfRessource.max then
                selfRessource.quantity = math.min(selfRessource.quantity+ressource.quantity, selfRessource.max)
            else
                selfRessource.quantity = selfRessource.quantity+ressource.quantity
            end
        end
    end
    entity.deduct = function (self, ressource)
        if not ressource.quantity or ressource.quantity < 0 then return end
        local name = ressource.name
        if self.ressources[name] then
            self.ressources[name].quantity = math.max(self.ressources[name].quantity-ressource.quantity, 0)
        end
    end
    entity.isDead = function (self)
        return not self:isAvailable(newRessource("life", 1))
    end
    entity.hit = function (self, damage)
        self:onHit(damage)
        if self:isDead() then 
            self:onDeath()
        end
    end
    entity.onHit = function (self, damage)
        assert(type(damage) == "number", "onHit function takes damage value!")
        if self.ressources.life then
            self:deduct(newRessource("life", damage))
        end
    end
    entity.onDeath = function (self) end

    entity.actions = {}
    entity.addAction = function (self, action)
        action.caster = self
        table.insert(self.actions, action)
    end

    return entity
end

function newRessource(ressourceType, quantity, max)
    local ressource
    if ressourceType.name then
        ressource = {name = ressourceType.name, quantity = quantity, max = max}
    else
        ressource = {name = ressourceTypes[ressourceType].name, quantity = quantity, max = max}
    end
    return ressource
end

ressourceTypes = {life = {name = "life"}}

function testLivingEntityRessource()
    local livingEntity = applyParams(newLivingEntity(), {i = 5, j=5, color={0, 1, 0}, spriteSet = {path = "sprite/oldHero.png", width = 16, height = 16}})
    livingEntity:initEntity()

    livingEntity.ressources.life = newRessource("life", 10, 10)
    livingEntity:hit(2)
    assert(livingEntity.ressources.life.quantity == 8, "livingEntity:hit(damage) failed!")
    print("livingEntity:hit(damage) Ok")

    livingEntity:credit(newRessource("life", 3))
    assert(livingEntity.ressources.life.quantity == 10, "livingEntity:credit() action failed! expected livingEntity life 10, found "..livingEntity.ressources.life.quantity)
    print("livingEntity:credit() Ok")
    livingEntity:hit(11)
    assert(livingEntity:isDead(), "living entity not dead after deadly hit")
    print("livingEntity:isDead() OK")
end