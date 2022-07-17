actionTypesKeys = {"attack", "move", "support"}
actionTypes = {
    attack = {name = "attack", img = nil},
    move = {name = "move", img = nil},
    support = {name = "support", img = nil}
}

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
                    return false
                end
            end
            return true
        end,
        try = function (self, targetCell)
            if self:isCostAvailable() and self:isTargetValid(targetCell) then
                if self:activate(targetCell) then
                    for r, ressource in pairs(self.cost) do
                        self.caster:deduct(ressource)
                    end
                    return true
                end
            end
            return false
        end
    }
    return action
end

actions = {
    Heal = function (params)
        local heal = newAction()
        heal.actionType = "support"
        heal.name = "HEAL"
        heal.usableOnSelf = true
        heal.range = 0
        heal.healAmout = 1
        heal.isTargetValid = function (self, targetCell)
            return self.caster.i == targetCell.i and self.caster.j == targetCell.j
        end
        heal.activate = function (self)
            self.caster:credit(newRessource("life", self.healAmout))
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
            if entityTargeted and entityTargeted.hit then
                entityTargeted:hit(self.damage)
                return true
            end
            return false
        end
        meleeAttack.getDescription = function(self)
            return "Deals "..self.damage.." point(s) of damage at close range. A target is required."
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
            return self.caster:move(targetCell.i, targetCell.j)
        end
        walk.getDescription = function (self)
            return "Moves up to "..self.range.." tiles."
        end
        return applyParams(walk, params)
    end, 
    MagicMissile = function (params)
        local magicMissile = newAction()
        magicMissile.name = "MAGIC MISSILE"
        magicMissile.actionType = "attack"
        magicMissile.damage = 1
        magicMissile.range = 4
        magicMissile.cost = {newRessource("mana", 1)}
        magicMissile.activate = function (self, targetCell)
            local entityTargeted = getEntityOn(targetCell.i, targetCell.j)
            if entityTargeted and entityTargeted.hit then
                entityTargeted:hit(self.damage)
                return true
            end
            return false
        end
        magicMissile.getDescription = function (self)
            return "Expends mana to fire a projectile dealing "..self.damage.." to the target. A target is required."
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