equipmentTypes = {"mainhand", "offhand", "armor"}
itemTypes = {"sword", "armor"}

ressourceTypes = {
  life = {name = "life"},
  mana = {name = "mana"},
  stamina = {name = "stamina"},
  ki = {name = "ki"},
  watt = {name = "watt"},
  faith = {name = "faith"},
  rage = {name = "rage"}
} 

classes = {
  --example, to be removed
  formerHero = {
    setup = function (entity)
      entity.class = "formerHero"
      entity:addRessourceBank("life", 10)
      entity:addRessourceBank("mana", 3)
      entity:addAction(actions.Heal())
      entity:addAction(actions.MagicMissile())
    end
  },


  fighter = {
    name = "fighter",
    setup = function (entity)
      entity.class = "fighter"
      entity:addRessourceBank("life", 10)
    end
  },
  mage = {
    name = "mage",
    setup = function (entity)
      entity.class = "mage"
      entity:addRessourceBank("life", 10)
      entity:addRessourceBank("mana", 10)
      entity:addAction(actions.MagicMissile())
      entity:addGameplayEvent("fightStart", function ()
        entity:credit(newRessource("mana", entity.ressources["mana"].max))
        for n = 1, 3 do
          local manaline = newEntity()
          manaline.color = {0, 0, 1}
          manaline.blockPath = false
          manaline.i, manaline.j = entity.i +n, entity.j + n
          manaline.onWalkingOn = function (self, walkingEntity)
            if walkingEntity.ressources["mana"] and walkingEntity.ressources["mana"].quantity < walkingEntity.ressources["mana"].max then
              walkingEntity:credit(newRessource("mana", 1))
              self.terminated = true
            end
          end
          manaline:initEntity()
        end
      end)
      --add fightStart Event for spawning manalines: "https://shadowrun.fandom.com/wiki/Manalines_and_power_sites" 
      --for mana regeneration
    end
  },
  warrior = {
    name = "warrior",
    setup = function (entity)
      entity.class = "warrior"
      entity:addRessourceBank("life", 10)
      entity:addRessourceBank("rage", 100, 0)
      entity:addAction(actions.Enrage())
    end
  },
  monk = {name = "monk",
    setup = function (entity)
      entity.class = "monk"
      entity.stats.bonusWalkRange = 1
      entity:addRessourceBank("life", 10)
      entity:addRessourceBank("ki", 5, 0)
    end
  },
  engineer = {name = "engineer"},
  priest = {name = "priest"}
}

races = {
  fey = {},
  vampire = {},
  demon = {},
  angel = {},
  chtonic = {},
  beastkin = {}
}

actions = {
  Heal = function (params)
      local heal = newAction()
      heal.actionType = "magic"
      heal.name = "HEAL"
      heal.usableOnSelf = true
      heal.range = 0
      heal.healAmout = 1
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
  WeaponAttack = function(params)
      local weaponAttack = newAction()
      weaponAttack.name = "WEAPON ATTACK"
      weaponAttack.actionType = "attack"
      weaponAttack.activate = function (self, targetCell)
          local entityTargeted = getEntityOn(targetCell.i, targetCell.j)
          if (entityTargeted ~= player and self.caster ~= player) and mode ~= "testing" then return false end
          if entityTargeted and entityTargeted.hit then
              if self.caster == player then audioManager:playSound(audioManager.sounds.attack) end
              entityTargeted:hit(self.caster:getEffectiveStat("weaponAttack"))
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
              if self.caster.ressources["rage"] then self.caster:credit(newRessource("rage", 10)) end
              return true
          end
          return false
      end
      weaponAttack.getDescription = function(self)
          return "Deals "..(self.caster:getEffectiveStat("weaponAttack")).." point(s) of damage at close range.\n A target is required."
      end
      return applyParams(weaponAttack, params)
  end,
  Walk = function(params)
      local walk = newAction()
      walk.name = "WALK"
      walk.actionType = "move"
      walk.fixedRange = false
      walk.getEffectiveRange = function (self)
        return self.range+self.caster:getEffectiveStat("bonusWalkRange")
      end
      walk.isTargetValid = function (self, targetCell)
          local d = manhattanDistance(self.caster, targetCell)
          if d > 0 and d <= self:getEffectiveRange() then
              local entityTargeted = getEntityOn(targetCell.i, targetCell.j)
              return (not entityTargeted) or (not entityTargeted.blockPath)
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
          return "Moves up to "..self:getEffectiveRange().." tiles."
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
          if (entityTargeted ~= player and self.caster ~= player) and mode ~= "testing" then return false end
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
  end,
  Enrage = function (params)
    local enrage = newAction()
    enrage.name = "ENRRRRAGE"
    enrage.actionType = "miscellaneous"
    enrage.range = 0  
    enrage.usableOnSelf = true
    enrage.cost = {newRessource("rage", 40)}
    enrage.activate = function (self, targetCell)
      self.caster:addEffect({name="raging", stats = {weaponAttack = 1}, duration = 6, effectType = "bonus"})
      return true
    end
    enrage.getDescription = function (self)
      return "RRAAAAAAAAAAAHHHHH!!! [gain 1 weapon attack for 6 turns]"
    end
    return applyParams(enrage, params)
  end
}

ennemyTypes = {
  basic = function ()
    ennemy = applyParams(newLivingEntity(), {image = oldHeroImage, w=32, h=32, color = {0.8, 0.8, 0.8}, spriteSet = {width = 16, height = 16}})
    ennemy:addRessourceBank("life", 3)
    ennemy:addAction(actions.Walk())
    ennemy:addAction(actions.WeaponAttack({damage = 1}))
    ennemy:initEntity()
    return ennemy
  end,
  tank = function ()
    ennemy = applyParams(newLivingEntity(), {image = oldHeroImage, w=32, h=32, color = {1, 0, 1}, spriteSet = {width = 16, height = 16}})
    ennemy:addRessourceBank("life", 3)
    ennemy:addAction(actions.Walk())
    ennemy:addAction(actions.WeaponAttack({damage = 1}))
    ennemy:initEntity()
    return ennemy
  end,
  runner  = function ()
    ennemy = applyParams(newLivingEntity(), {image = oldHeroImage, w=32, h=32, color = {0, 0, 1}, spriteSet = {width = 16, height = 16}})
    ennemy:addRessourceBank("life", 5)
    ennemy:addAction(actions.Walk({range = 3}))
    ennemy:addAction(actions.WeaponAttack({damage = 1}))
    
    ennemy:initEntity()
    return ennemy
  end,
  oneshot  = function ()
    ennemy = applyParams(newLivingEntity(), {image = oldHeroImage, w=32, h=32, color = {1, 0, 0}, spriteSet = {width = 16, height = 16}})
    ennemy:addRessourceBank("life", 1)
    ennemy:addAction(actions.Walk())
    ennemy:addAction(actions.WeaponAttack({damage = 5}))
    
    ennemy:initEntity()
    return ennemy
  end,
  boss  = function ()
    ennemy = applyParams(newLivingEntity(), {image = mageImage, w=32, h=32, color = {1, 1, 1}, spriteSet = {width = 20, height = 20}})
    ennemy:addRessourceBank("life", 30, 20)
    ennemy:addRessourceBank("mana", 10)
    
    ennemy:addAction(actions.Walk({range=2}))
    ennemy:addAction(actions.WeaponAttack({damage = 2}))
    ennemy:addAction(actions.MagicMissile({range = 3,damage = 3}))
    ennemy:addAction(actions.Heal({healAmout = 1, cost = {newRessource("mana", 1)}}))
    
    
    ennemy:initEntity()
    return ennemy
  end
}

--used stats:
usedStats= {
  armor = "reduces damage taken by armor value", --file entity.lua > function newLivingEntity > function entity.onHit
  weaponAttack = "increases meleeAttack action damage by value", -- file data.lua > table actions.WeaponAttack
  bonusWalkRange = "increases walk action range by value" -- file data.lua > table actions.Walk
}