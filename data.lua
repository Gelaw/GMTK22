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
      entity:addRessourceBank("life", 10)
      entity:addRessourceBank("mana", 3)
      entity:addAction(actions.MeleeAttack())
      entity:addAction(actions.Heal())
      entity:addAction(actions.MagicMissile())
      entity:addAction(actions.Walk({range=2}))
    end
  },


  fighter = {
    name = "fighter",
    setup = function (entity)
      entity:addRessourceBank("life", 10)
      entity:addRessourceBank("rage", 100)
      entity:addAction(actions.MeleeAttack({cost = {newRessource("rage", 10)}}))
      entity:addAction(actions.Walk({range=2}))
    end},
  mage = {name = "mage"},
  monk = {name = "monk"},
  engineer = {name = "engineer"},
  priest = {name = "priest"},
  warrior = {name = "warrior"}
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
      meleeAttack.activate = function (self, targetCell)
          local entityTargeted = getEntityOn(targetCell.i, targetCell.j)
          if (entityTargeted ~= player and self.caster ~= player) and mode ~= "testing" then return false end
          if entityTargeted and entityTargeted.hit then
              if self.caster == player then audioManager:playSound(audioManager.sounds.attack) end
              entityTargeted:hit((self.caster.stats.meleeAttack or 0) + (self.caster.equipmentStats.meleeAttack or 0))
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
          return "Deals "..(self.caster.stats.meleeAttack or 0) + (self.caster.equipmentStats.meleeAttack or 0).." point(s) of damage at close range.\n A target is required."
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
  end
}

ennemyTypes = {
  basic = function ()
    ennemy = applyParams(newLivingEntity(), {image = oldHeroImage, w=32, h=32, color = {0.8, 0.8, 0.8}, spriteSet = {width = 16, height = 16}})
    ennemy:addRessourceBank("life", 3)
    ennemy:addAction(actions.Walk())
    ennemy:addAction(actions.MeleeAttack({damage = 1}))
    ennemy:initEntity()
    return ennemy
  end,
  tank = function ()
    ennemy = applyParams(newLivingEntity(), {image = oldHeroImage, w=32, h=32, color = {1, 0, 1}, spriteSet = {width = 16, height = 16}})
    ennemy:addRessourceBank("life", 3)
    ennemy:addAction(actions.Walk())
    ennemy:addAction(actions.MeleeAttack({damage = 1}))
    ennemy:initEntity()
    return ennemy
  end,
  runner  = function ()
    ennemy = applyParams(newLivingEntity(), {image = oldHeroImage, w=32, h=32, color = {0, 0, 1}, spriteSet = {width = 16, height = 16}})
    ennemy:addRessourceBank("life", 5)
    ennemy:addAction(actions.Walk({range = 3}))
    ennemy:addAction(actions.MeleeAttack({damage = 1}))
    
    ennemy:initEntity()
    return ennemy
  end,
  oneshot  = function ()
    ennemy = applyParams(newLivingEntity(), {image = oldHeroImage, w=32, h=32, color = {1, 0, 0}, spriteSet = {width = 16, height = 16}})
    ennemy:addRessourceBank("life", 1)
    ennemy:addAction(actions.Walk())
    ennemy:addAction(actions.MeleeAttack({damage = 5}))
    
    ennemy:initEntity()
    return ennemy
  end,
  boss  = function ()
    ennemy = applyParams(newLivingEntity(), {image = mageImage, w=32, h=32, color = {1, 1, 1}, spriteSet = {width = 20, height = 20}})
    ennemy:addRessourceBank("life", 30, 20)
    ennemy:addRessourceBank("mana", 10)
    
    ennemy:addAction(actions.Walk({range=2}))
    ennemy:addAction(actions.MeleeAttack({damage = 2}))
    ennemy:addAction(actions.MagicMissile({range = 3,damage = 3}))
    ennemy:addAction(actions.Heal({healAmout = 1, cost = {newRessource("mana", 1)}}))
    
    
    ennemy:initEntity()
    return ennemy
  end
}