actionTypes = {
    attack = {name = "attack"},
    move = {name = "move"},
    support = {name = "support"}
}

function newAction()
    local action = {
        name = "defaultActionName",
        range = 1,
        usableOnSelf = false,
        caster = nil,
        cost = {},

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
                return self:activate(targetCell)
            end
            return false
        end
    }
    return action
end

actions = {
    Heal = function (params)
        local heal = newAction()
        heal.actionType = actionTypes.support
        heal.usableOnSelf = true
        heal.range = 0
        heal.healAmout = 1
        heal.isTargetValid = function (self, targetCell)
            return self.caster.i == targetCell.i and self.caster.j == targetCell.j
        end
        heal.activate = function (self)
            self.caster:credit(newRessource("life", self.healAmout))
        end
        return applyParams(heal, params)
    end,
    MeleeAttack = function(params)
        local meleeAttack = newAction()

        meleeAttack.actionType = actionTypes.attack
        meleeAttack.damage = 2
        meleeAttack.activate = function (self, targetCell)
            local entityTargeted = getEntityOn(targetCell.i, targetCell.j)
            if entityTargeted and entityTargeted.hit then
                entityTargeted:hit(self.damage)
            end
        end

        return applyParams(meleeAttack, params)
    end,
    Walk = function(params)
        local walk = newAction()

        walk.actionType = actionTypes.move
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
        return applyParams(walk, params)
    end
}

function manhattanDistance(a, b)
    return math.abs(a.i - b.i) + math.abs(a.j - b.j)
end


function testActions()
    local target = applyParams(newLivingEntity(), {i=2, j=1, color = {1, 0, 0}, spriteSet = {path = "sprite/oldHero.png", width = 16, height = 16}})
    target:initEntity()
    target.ressources.life = newRessource("life", 10, 10)

    local caster = applyParams(newLivingEntity(), {i=1, j=2, color = {0, 0, 1}, spriteSet = {path = "sprite/oldHero.png", width = 16, height = 16}})
    caster:initEntity()
    caster.ressources.life = newRessource("life", 10, 10)
    local walkAction = actions.Walk()
    caster:addAction(walkAction)
    walkAction:try({i=1, j=1})
    assert(caster.i==1, caster.j==1, "walk action failed!")
    print("walk action OK")

    local meleeAttackAction = actions.MeleeAttack()
    caster:addAction(meleeAttackAction)
    meleeAttackAction:try({i=2, j=1})
    assert(target.ressources.life.quantity==8, "meleeAttack action failed! expected target life 8, found "..target.ressources.life.quantity)
    print("meleeAttack action Ok")

    local healAction = actions.Heal()
    target:addAction(healAction)
    healAction:try({i=2, j=1})
    assert(target.ressources.life.quantity==9, "heal action failed! expected target life 9, found "..target.ressources.life.quantity)
    print("heal action Ok")
end