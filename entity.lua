function newEntity()
    local entity = {}
    
    --i, j : board coordinates
    entity.i, entity.j = nil
    
    --x, y : screen coordinates, used for animations 
    entity.x, entity.y = 0, 0  

    -- snapping speed : speed of correction of x,y pos (relative to i,j pos)
    entity.snappingSpeed = 30 * tileSize

    --display size
    entity.w, entity.h = tileSize, tileSize

     --does entity prevent from walking on his cell
    entity.blockPath = true
    
    -- gameplay event callback (on fightStart, newTurn, damage taken, etc)
    entity.gameplayEvents = {}
    entity.addGameplayEvent = function (self, event, callback)
        if not self.gameplayEvents[event] then
            self.gameplayEvents[event] = {}
        end
        table.insert(self.gameplayEvents[event], callback)
    end
    entity.getGameplayEvents = function (self, event)
        return self.gameplayEvents[event]
    end
    entity.triggerGameplayEvent = function (self, event, eventualVariable)
        local callbacks = self:getGameplayEvents(event) or {}
        for c, callb in pairs(callbacks) do
          callb(eventualVariable)
        end
    end

    --updates
    entity.updates = {
        function (self, dt)
            if not self.i or not self.j then return end
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
    
    -- move to new i,j position
    entity.move = function(self, newI, newJ)
        if not map[newI] or not map[newI][newJ] then return false end
        local entityOnNewPos = getEntityOn(newI, newJ)
        if entityOnNewPos then
            if entityOnNewPos.blockPath then
                return false
            else
                if entityOnNewPos.onWalkingOn then
                    entityOnNewPos:onWalkingOn(self)
                end
            end
        end
        self.i, self.j = newI, newJ
        return true
    end
    
    -- move to x,y pos corresponding to i,j pos instantly
    entity.snapToGrid = function (self)
        self.x, self.y = gridToScreen(self.i, self.j)
    end
    
    entity.draw = function (self)
        love.graphics.setColor(self.color or {.8, 0, .8})
        love.graphics.translate(self.x+.5*zoomX*tileSize, self.y+.5*zoomY*tileSize)
        love.graphics.circle("fill", 0, 0, .5*zoomY*tileSize-.5*self.h)
    end

    
    entity.loadAnimation = function (self, spriteSet)
        if self.spriteSet then
            self.animation = newAnimation(self.image or love.graphics.newImage(self.spriteSet.path or spriteSet.path or spriteSet),
            self.spriteSet.width or spriteSet.width or 16, self.spriteSet.height or spriteSet.height or 16, 1, 32, 32)
        end
        if self.animation then
            self.draw = function (self)
                love.graphics.setColor(self.color or {1, 1, 1})
                love.graphics.translate(self.x+.5*zoomX*tileSize, self.y+.5*zoomY*tileSize-.5*self.h)
                if self.isDead and self:isDead() then
                    love.graphics.rotate(math.rad(-90))
                end
                self.animation:draw()
            end
            table.insert(self.updates,
            function (self, dt)
                self.animation:update(dt)
            end)
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
    

    --ressources functions ( used for life, mana, etc )
    entity.ressources = {}
    entity.addRessourceBank = function (self, ressource, capacity, defaultValue)
        previousCapacity, previousAmount = 0, 0
        if self.ressources[ressource] then
            previousCapacity = self.ressources[ressource].max
            previousAmount = self.ressources[ressource].quantity
        end
        print(ressource, (defaultValue or capacity)+previousAmount, capacity+previousCapacity)
        self.ressources[ressource] = newRessource(ressource, (defaultValue or capacity)+previousAmount, capacity+previousCapacity)
    end
    entity.removeRessourceBank = function (self, ressource, capacity)

    end
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
        local absoluteDamage = damage - self:getEffectiveStat("armor")
        if self.ressources.life and absoluteDamage > 0 then
            self:deduct(newRessource("life", absoluteDamage))
        end
    end
    entity.onDeath = function (self) end
    

    entity.actions = {}
    entity.addAction = function (self, action)
        action.caster = self
        table.insert(self.actions, action)
    end

    
    --[[
        stats are used for bonuses of entities
        can be :-inherent to entity (in entity.stats)
                -from equipmnent  (in entity.equipmentStats)
                -from temporary effect (in entity.activeEffects)

        stats are described in data.lua > usedStats table

        to get current value of a stat (from all sources) use entity.getEffectiveStat( statName )
    ]]--
    entity.stats = {meleeAttack = 1}
    entity.addStat = function (self, statName, value, mode)
        if mode == "overwrite" or self.stats[statName] == nil  then
            self.stats[statName] = value
            return
        end
        self.stats[statName] = self.stats[statName] + value
    end
    entity.addStats = function (self, stats)
        for s, stat in pairs(stats) do
            self:addStat(s, stat)
        end
    end

    entity.equipmentStats = {}
    entity.equipment = {mainHand = nil, offhand = nil, armor = nil}
    entity.inventory = {size = 0}
    entity.addToInventory = function (self, item)
        if self.inventory.size <= #self.inventory then
            table.remove(self.inventory.size, 1)
        end
        table.insert(self.inventory, item)
    end

    entity.equip = function (self, item)
        if self.equipment[item.equipmentType] then
            self:addToInventory(self.equipment[item.equipmentType])
        end
        self.equipment[item.equipmentType] = item
        self:recalculateEquipmentStats()
    end

    entity.unequip = function(self, slot)
        local item = self.equipment[slot]
        self.equipment[slot] = nil
        self:addToInventory(item)
        self:recalculateEquipmentStats()
        return item
    end
    
    entity.recalculateEquipmentStats = function (self)
        self.equipmentStats = {}
        for i, item in pairs(self.equipment) do
            for s, stat in pairs(item.stats) do
                self.equipmentStats[s] = (self.equipmentStats[s] or 0) + stat
            end
        end
    end

    
    entity.activeEffects = {}
    entity.addEffect = function (self, effect)
        table.insert(self.activeEffects, effect)
        self:recalculateEffectStats()
    end
    entity.tickEffects = function (self)
        local effectsChanged = false
        for e = #self.activeEffects, 1, -1 do
            local effect = self.activeEffects[e]
            if effect.duration then
                effect.duration = effect.duration - 1
                if effect.duration <= 0 then
                    table.remove(self.activeEffects, e)
                    effectsChanged = true
                end
            end
        end
        if effectsChanged then self:recalculateEffectStats() end
    end
    entity.effectStats = {}
    entity.recalculateEffectStats = function (self)
        self.effectStats = {}
        for e, effect in pairs(self.activeEffects) do
            for s, stat in pairs(effect.stats) do
                self.effectStats[s] = (self.effectStats[s] or 0) + stat * (effect.stack or 1)
            end
        end
    end

    entity.getEffectiveStat = function (self, stat)
       return (self.stats[stat] or 0) + (self.equipmentStats[stat] or 0) + (self.effectStats[stat] or 0)
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

function newItemEntity(item, i, j)
    local ie = newEntity()
    ie.item = item
    ie.i, ie.j = i, j
    ie.blockPath = false
    ie.onWalkingOn = function (self, walkingEntity)
        if walkingEntity.equip then
            walkingEntity:equip(self.item)
            self.terminated = true
        end
    end
    ie:initEntity()
    ie.draw = function (self)
        love.graphics.setColor(self.color or {1, 1, 1})
        love.graphics.translate(self.x, self.y)
        self.item:drawSprite()
    end
end
