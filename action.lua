actionTypesKeys = {"attack", "move", "magic", "miscellaneous"}
actionTypes = {
    attack = {name = "attack", img = nil},
    move = {name = "move", img = nil},
    magic = {name = "magic", img = nil},
    miscellaneous = {name = "miscellaneous", img = nil}
}

function setupActionTypesImages()
    actionTypes.attack.img = love.graphics.newImage("src/img/dice/attack.png")
    actionTypes.move.img = love.graphics.newImage("/src/img/dice/move.png")
    actionTypes.magic.img = love.graphics.newImage("src/img/dice/support.png")
    local canvas = love.graphics.newCanvas(254, 254)
    love.graphics.setCanvas(canvas)
    love.graphics.scale(2)
    love.graphics.print("?", .5*.5*254-.5*font:getWidth("?"), .5*.5*254-.5*font:getHeight())
    love.graphics.setCanvas()
    actionTypes.miscellaneous.img = love.graphics.newImage(canvas:newImageData())
  
end

function newAction()
    local action = {
        name = "defaultActionName",
        range = 1,
        usableOnSelf = false,
        caster = nil,
        cost = {},
        getDescription = function (self) return "This is the default action description" end,
        activate = function(self) end,
        isTargetValid = function (self, targetCell)
            local d = manhattanDistance(self.caster, targetCell)
            if d > 0 then
                return self.range >= d
            else
                return usableOnSelf
            end
        end,
        isCostAvailable = function (self)
            for r, ressource in pairs(self.cost) do
                if not self.caster:isAvailable(ressource) then
                    if self.caster == player then audioManager:playSound(audioManager.sounds.wrong) end
                    return false
                end
            end
            return true
        end,
        try = function (self, targetCell)
            if not self:isCostAvailable() then return false, self.name.."'s cost isn't available" end
            if not self:isTargetValid(targetCell) then return false, "target isn't valid for "..self.name end
            if not self:activate(targetCell) then return false, self.name .. " activation failed" end
            for r, ressource in pairs(self.cost) do
                self.caster:deduct(ressource)
            end
            return true
        end
    }
    return action
end

actions = {
    Heal = function (params)
        local heal = newAction()
        heal.actionType = "magic"
        heal.name = "HEAL"
        heal.usableOnSelf = true
        heal.range = 0
        heal.healAmout = 1
        heal.isTargetValid = function (self, targetCell)
            return self.caster.i == targetCell.i and self.caster.j == targetCell.j
        end
        heal.activate = function (self, targetCell)
            self.caster:credit(newRessource("life", self.healAmout))
            if self.caster == player then audioManager:playSound(audioManager.sounds.heal) end
            local tx, ty = gridToScreen(targetCell.i+.5, targetCell.j+.5)
            table.insert(particuleEffects, {
                            x=tx, y=ty, color = {1, .2, .2}, nudge = 5, size = 3, timeLeft = 1.5,
                            pluslygon = {-1,-1,  -1,-3,  1,-3,  1,-1,  3,-1,  3,1,  1,1,  1,3,  -1,3,  -1,1,  -3,1,  -3,-1},
                            draw = function (self)
                              love.graphics.translate(self.x, self.y)
                              love.graphics.scale(2)
                              love.graphics.setColor(self.color)
                              local t = love.timer.getTime() % 3600
                              for i = 1, 4 do
                                love.graphics.push()
                                love.graphics.translate(math.cos(10*t+i*39)*5, math.cos(12*t+i*22)*5)
                                love.graphics.polygon("fill", self.pluslygon)
                                love.graphics.pop()
                              end
                            end
                          })
            return true
        end
        heal.getDescription = function(self)
            return "Recovers "..self.healAmout.." point of life. Has no effect if already on full Life."
        end
        return applyParams(heal, params)
    end,
    MeleeAttack = function(params)
        local meleeAttack = newAction()
        meleeAttack.name = "MELEE ATTACK"
        meleeAttack.actionType = "attack"
        meleeAttack.damage = 2
        meleeAttack.activate = function (self, targetCell)
            local entityTargeted = getEntityOn(targetCell.i, targetCell.j)
            if entityTargeted ~= player and self.caster ~= player then return false end
            if entityTargeted and entityTargeted.hit then
                if self.caster == player then audioManager:playSound(audioManager.sounds.attack) end
                entityTargeted:hit(self.damage)
                local tx, ty = gridToScreen(targetCell.i+.5, targetCell.j+.5)
                local cx, cy = gridToScreen(self.caster.i+.5, self.caster.j+.5)
                local Effect = {x = cx, y = cy, d = math.dist(cx, cy, tx, ty), a = math.angle(cx, cy, tx, ty),timeLeft = .3,
                draw = function (self)
                    love.graphics.setColor(1, 1, 1)
                    love.graphics.translate(self.x, self.y)
                    local angle = self.a + self.timeLeft*math.pi
                    love.graphics.line(0, 0, self.d*math.cos(angle), self.d*math.sin(angle))
                end}

                table.insert(particuleEffects, Effect)
                return true
            end
            return false
        end
        meleeAttack.getDescription = function(self)
            return "Deals "..self.damage.." point(s) of damage at close range.\n A target is required."
        end
        return applyParams(meleeAttack, params)
    end,
    Walk = function(params)
        local walk = newAction()
        walk.name = "WALK"
        walk.actionType = "move"
        walk.isTargetValid = function (self, targetCell)
            local d = manhattanDistance(self.caster, targetCell)
            if d > 0 and d <= self.range then
                local entityTargeted = getEntityOn(targetCell.i, targetCell.j)
                return not entityTargeted or entityTargeted.blockPath
            end
        end
        walk.activate = function (self, targetCell)
            if self.caster == player then audioManager:playSound(audioManager.sounds.walk) end
            local temp = {gridToScreen(self.caster.i+.5, self.caster.j+.5)}
            if self.caster:move(targetCell.i, targetCell.j) then
                table.insert(particuleEffects, {x=temp[1], y= temp[2], timeLeft = .5, draw = function(self)
                    love.graphics.setColor(1, 1, 1, self.timeLeft)
                    local time = love.timer.getTime()
                    for i = 1, 3 do
                        local x, y = 15*math.sin(i*time), 15*math.cos(i*time)
                        love.graphics.rectangle("fill", x+self.x-5, y+self.y-5, 10, 10)
                    end
                end})
                return true
            end
            return false
        end
        walk.getDescription = function (self)
            return "Moves up to "..self.range.." tiles."
        end
        return applyParams(walk, params)
    end, 
    MagicMissile = function (params)
        local magicMissile = newAction()
        magicMissile.name = "MAGIC MISSILE"
        magicMissile.actionType = "magic"
        magicMissile.damage = 1
        magicMissile.range = 4
        magicMissile.cost = {newRessource("mana", 1)}
        magicMissile.activate = function (self, targetCell)
            local entityTargeted = getEntityOn(targetCell.i, targetCell.j)
            if entityTargeted ~= player and self.caster ~= player then return false end
            if entityTargeted and entityTargeted.hit then
                if self.caster == player then audioManager:playSound(audioManager.sounds.magic) end
                entityTargeted:hit(self.damage)
                local tx, ty = gridToScreen(targetCell.i+.5, targetCell.j+.5)
                local cx, cy = gridToScreen(self.caster.i+.5, self.caster.j+.5)
                local Effect = {x = cx, y = cy, tx = tx, ty =ty, timeLeft = .5,
                draw = function (self)
                    love.graphics.setColor(.5, 0, 1, .3)
                    love.graphics.translate(self.x + (1-self.timeLeft/.5)*(self.tx - self.x), self.y + (1-self.timeLeft/.5)*(self.ty - self.y))
                    love.graphics.circle("fill", 0, 0, 10)
                end}

                table.insert(particuleEffects, Effect)
                return true
            end
            return false
        end
        magicMissile.getDescription = function (self)
            return "Expends mana to fire a projectile dealing "..self.damage.." to the target.\n A target is required."
        end
        return applyParams(magicMissile, params)
    end
}

function manhattanDistance(a, b)
    return math.abs(a.i - b.i) + math.abs(a.j - b.j)
end


function testActions()
    local target = applyParams(newLivingEntity(), {i=2, j=1, color = {1, 0, 0}, spriteSet = {path = "src/img/sprites/oldHero.png", width = 16, height = 16}})
    target:initEntity()
    target.ressources.life = newRessource("life", 10, 10)

    local caster = applyParams(newLivingEntity(), {i=1, j=2, color = {0, 0, 1}, spriteSet = {path = "src/img/sprites/oldHero.png", width = 16, height = 16}})
    caster:initEntity()
    caster.ressources.life = newRessource("life", 10, 10)
    local walkAction = actions.Walk()
    caster:addAction(walkAction)
    print("walkAction try ", walkAction:try({i=1, j=1}))
    assert(caster.i==1, caster.j==1, "walk action failed!")
    print("walk action OK")

    local meleeAttackAction = actions.MeleeAttack()
    caster:addAction(meleeAttackAction)
    print("meleeAttackAction try ", meleeAttackAction:try({i=2, j=1}))
    assert(target.ressources.life.quantity==8, "meleeAttack action failed! expected target life 8, found "..target.ressources.life.quantity)
    print("meleeAttack action Ok")

    local healAction = actions.Heal()
    target:addAction(healAction)
    print("healAction try ", healAction:try({i=2, j=1}))
    assert(target.ressources.life.quantity==9, "heal action failed! expected target life 9, found "..target.ressources.life.quantity)
    print("heal action Ok")

    caster.ressources.mana = newRessource("mana", 3, 3)
    local magicMissile = actions.MagicMissile()
    caster:addAction(magicMissile)
    print("magicMissile try ", magicMissile:try({i=2, j=1}))
    assert(target.ressources.life.quantity==8, "magicMissile action failed! expected target life 8, found "..target.ressources.life.quantity)
    assert(caster.ressources.mana.quantity==2, "magicMissile didn't consume his mana cost, expected caster mana 2, found "..caster.ressources.mana.quantity)
    print("magicMissile action Ok")
end