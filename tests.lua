
function testActions()
    local target = applyParams(newLivingEntity(), {i=2, j=1, color = {1, 0, 0}, spriteSet = {path = "src/img/sprites/oldHero.png", width = 16, height = 16}})
    target:initEntity()
    target.ressources.life = newRessource("life", 10, 10)

    local caster = applyParams(newLivingEntity(), {i=1, j=2, color = {0, 0, 1}, stats = {meleeAttack = 2}, spriteSet = {path = "src/img/sprites/oldHero.png", width = 16, height = 16}})
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

function testLivingEntityRessource()
    local livingEntity = applyParams(newLivingEntity(), {i = 5, j=5, color={0, 1, 0}, spriteSet = {path = "src/img/sprites/oldHero.png", width = 16, height = 16}})
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