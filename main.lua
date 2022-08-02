require "base"
require "ui"
require "map"
require "entity"
require "action"
require "mapFile"
require "item"

function projectSetup()
  
  --font
  love.graphics.setBackgroundColor(.3, .3, .3)
  font = love.graphics.newFont("src/fonts/Quantum.otf", 25)
  love.graphics.setFont(font)

  --Load images
  diceImg = love.graphics.newImage("src/img/dice/dice.png")
  fuzzyDicesImages = {
    love.graphics.newImage("src/img/dice_frame/deP1.png"),
    love.graphics.newImage("src/img/dice_frame/deP2.png"),
    love.graphics.newImage("src/img/dice_frame/deP3.png"),
    love.graphics.newImage("src/img/dice_frame/deP4.png"),
    love.graphics.newImage("src/img/dice_frame/deP5.png")
  }
  
  dungeonSprites = love.graphics.newImage("src/img/sprites/ProjectUtumno_full.png")
  spriteSize = 32

  todoQuad = love.graphics.newQuad(37 * spriteSize,  50* spriteSize, spriteSize, spriteSize,
  dungeonSprites:getWidth(), dungeonSprites:getHeight())

  itemsQuads = {
    sword = love.graphics.newQuad(2 * spriteSize,  49* spriteSize, spriteSize, spriteSize,
    dungeonSprites:getWidth(), dungeonSprites:getHeight()),
    armor = love.graphics.newQuad(15 * spriteSize,  38* spriteSize, spriteSize, spriteSize,
    dungeonSprites:getWidth(), dungeonSprites:getHeight())
  }
  itemTest = newItem({name = "sword", quad = itemsQuads.sword, stats = {meleeAttack = 1}})
  addDrawFunction(
      function ()
          love.graphics.origin()
          love.graphics.translate(50, 50)
          itemTest:drawSprite()
      end, 9
  )

  oldHeroImage = love.graphics.newImage("src/img/sprites/oldHero.png")
  knightImage = love.graphics.newImage("src/img/sprites/knight.png")
  mageImage = love.graphics.newImage("src/img/sprites/mage.png")

  setupActionTypesImages()

  gmtkImage = love.graphics.newImage("src/img/gmtkLogo.jpg")
  ssLogo = love.graphics.newImage("src/img/SacraScriptura.png")
  menuBackground = love.graphics.newImage("src/img/Menu.png")
  
  --load music and sounds
  audioManager:loadMusic("mainTheme", "src/snd/test3.mp3")
  audioManager:loadMusic("prairieTheme", "src/snd/prairie.mp3")

  audioManager:loadSoundEffect("click",       "src/snd/soundEffect/snd_btnClick.mp3")
  audioManager:loadSoundEffect("attack",      "src/snd/soundEffect/snd_heroAttack.mp3")
  audioManager:loadSoundEffect("heal",        "src/snd/soundEffect/snd_heroHeal.mp3")
  audioManager:loadSoundEffect("magic",       "src/snd/soundEffect/snd_heroMagic.mp3")
  audioManager:loadSoundEffect("walk",        "src/snd/soundEffect/snd_heroWalk.mp3")
  audioManager:loadSoundEffect("mouseclick",  "src/snd/soundEffect/snd_mouseClick.mp3")
  audioManager:loadSoundEffect("wrong",       "src/snd/soundEffect/snd_wrong.mp3")


 
  addDrawFunction(function ()
    if mapHidden then
      love.graphics.setColor(1,1,1)
      love.graphics.draw(menuBackground, -width*.5, -height*.5, 0, width/menuBackground:getWidth(), height/menuBackground:getHeight())
    end
  end, 1)

  game = {
    gameState = "unlaunched",
    nTurn = 1,
    level = 10,
    maxPrerolledTurns = 5,
    nextTurns = {},
    start = function(self)
      self.nTurn = 1
      victory.hidden = true
      mapHidden = false
      self.nextTurns = {"move", "move", "move", "move"}
      self.level = self.level + 1
      nextTurnUI:updateTurns()

      setupMap()
      fillMap()
      if not player then
        player = applyParams(newLivingEntity(), {image = knightImage, i = 3, j=3, w=32, h=32, spriteSet = {width = 20, height = 20}})
        player.ressources.life = newRessource("life", 10, 10)
        player.ressources.mana = newRessource("mana", 3, 3)
        player:equip(newItem({name = "chestplate",equipmentType="armor", itemType = "body armor", stats= {armor = 1}, quad = itemsQuads.armor}))
        player:equip(itemTest)
        player:addAction(actions.Walk({range=2}))
        player:addAction(actions.MeleeAttack())
        player:addAction(actions.Heal())
        player:addAction(actions.MagicMissile())
        player:initEntity()
        setupUpgrades()
      else
        for e, entity in pairs(entities) do
          entity.terminated = true
        end
        player.terminated = false
        upgradePlayer()
        player.i, player.j = 3, 3
        player.ressources.life.quantity = player.ressources.life.max
        player.ressources.mana.quantity = player.ressources.mana.max
        player:snapToGrid()
      end

      spawnTypes = {"oneshot"}
      if game.level >= 2 then
        table.insert(spawnTypes, "basic")
      end
      if game.level >= 3 then
        table.insert(spawnTypes, "runner")
      end
      if game.level >= 5 then
        table.insert(spawnTypes, "tank")
      end
      if game.level >= 10 then
        table.insert(spawnTypes, "boss")
      end
      forces = 0
      forceTable = {1, 2, 1, 4, 12}
      while forces < game.level do
        n = math.random(#spawnTypes)
        forces = forces + forceTable[n]
        spawn(spawnTypes[n])
      end
      rollDice()
    end,
    finish = function (self)
      self.level = 0
      player = nil
      for e, entity in pairs(entities) do
        entity.terminated = true
      end
    end,
    endTurn = function (self)
      selectedAction = nil
      if #self.nextTurns <1 then return end
      self:playIAs()
      if player:isDead() then
        defeat.hidden = false
      end
      table.remove(self.nextTurns, 1)
      nextTurnUI:updateTurns()
      rollDice()
      if #self.nextTurns == 0 then
        rollDice()
      end
      game.nTurn = game.nTurn + 1
    end,
    playIAs = function (self)
      local c = 0
      for e, entity in pairs(entities) do
        if entity ~= player and entity.isDead and not entity:isDead() then
          c = c + 1
          local availableActions = {}
          for a, action in pairs(entity.actions) do
            if action.actionType == self.nextTurns[1] then
              table.insert(availableActions, action)
            end
          end
          if #availableActions > 0 then
            local iachoice = availableActions[math.random(#availableActions)]
            if not iachoice:try({i=player.i, j=player.j}) and not iachoice:try({i=entity.i, j=entity.j}) then
              local distance = math.dist(player.i, player.j, entity.i, entity.j)
              local target = {i=entity.i, j=entity.j}
              local secondChoiceDistance = distance
              local secondChoiceTarget = target
              for i = - iachoice.range, iachoice.range do
                for j = -iachoice.range, iachoice.range do
                  local ni, nj = entity.i+i, entity.j+j
                  if map[ni] and map[ni][nj] and map[ni][nj] > 0 then
                    if manhattanDistance(entity, {i=ni, j=nj}) <= iachoice.range then
                      local d = math.dist(player.i, player.j, ni, nj)
                      if d < distance then
                        secondChoiceDistance = distance
                        secondChoiceTarget = target
                        target = {i=ni, j=nj}
                        distance = d
                      end
                    end
                  end
                end
              end
              if not iachoice:try(target) then
                iachoice:try(secondChoiceTarget)
              end
            end
          end
        end
      end
      if c == 0 then 
        victory.hidden = false
      end
    end
  }
  


  setupMap()
  setupMapView()
  setupTileset()
  setupUIs()

  
  diceDestination = {x=0, y=-height/2}

  modes = {"normal", "instantStart", "testing"}
  mode = "instantStart"
  if mode == "normal" then
    GMTKScreen = {
      image = gmtkImage,

      timeLeft = 3,
      x=-width/2, y=-height/2,
      draw = function (self)
        love.graphics.setColor(1, 1, 1, self.timeLeft)
        love.graphics.translate(self.x, self.y)
        love.graphics.draw(self.image, 0, 0, 0, width/self.image:getWidth(), height/self.image:getHeight())
        love.graphics.setColor(1,1,1)
        love.graphics.circle("fill",ssLogo:getWidth()/10+1,ssLogo:getHeight()/10,105)
        love.graphics.draw(ssLogo, 0, 0, 0, width/ssLogo:getWidth()/5, height/ssLogo:getHeight()/5)
        love.graphics.print("Sacra Scriptura",ssLogo:getWidth()/20, ssLogo:getHeight()/5)
      end,
      onTermination = function ()
        ShowMenu()
      end
    }
    table.insert(particuleEffects, GMTKScreen)
    return 
  end
  if mode == "instantStart" then
    HideMenu()
    game:start()
  end
  if mode == "testing" then
    HideMenu()
    game:start()
    testActions()
    testLivingEntityRessource()
  end
end

types = {
  basic = function ()
    ennemy = applyParams(newLivingEntity(), {image = oldHeroImage, w=32, h=32, color = {0.8, 0.8, 0.8}, spriteSet = {width = 16, height = 16}})
    ennemy.ressources.life = newRessource("life", 3, 3)
    ennemy:addAction(actions.Walk())
    ennemy:addAction(actions.MeleeAttack({damage = 1}))
    ennemy:initEntity()
    return ennemy
  end,
  tank = function ()
    ennemy = applyParams(newLivingEntity(), {image = oldHeroImage, w=32, h=32, color = {1, 0, 1}, spriteSet = {width = 16, height = 16}})
    ennemy.ressources.life = newRessource("life", 10, 10)
    ennemy:addAction(actions.Walk())
    ennemy:addAction(actions.MeleeAttack({damage = 1}))
    ennemy:initEntity()
    return ennemy
  end,
  runner  = function ()
    ennemy = applyParams(newLivingEntity(), {image = oldHeroImage, w=32, h=32, color = {0, 0, 1}, spriteSet = {width = 16, height = 16}})
    ennemy.ressources.life = newRessource("life", 3, 5)
    ennemy:addAction(actions.Walk({range = 3}))
    ennemy:addAction(actions.MeleeAttack({damage = 1}))

    ennemy:initEntity()
    return ennemy
  end,
  oneshot  = function ()
    ennemy = applyParams(newLivingEntity(), {image = oldHeroImage, w=32, h=32, color = {1, 0, 0}, spriteSet = {width = 16, height = 16}})
    ennemy.ressources.life = newRessource("life", 1, 1)
    ennemy:addAction(actions.Walk())
    ennemy:addAction(actions.MeleeAttack({damage = 5}))

    ennemy:initEntity()
    return ennemy
  end,
  boss  = function ()
    ennemy = applyParams(newLivingEntity(), {image = mageImage, w=32, h=32, color = {1, 1, 1}, spriteSet = {width = 20, height = 20}})
    ennemy.ressources.life = newRessource("life", 20, 30)
    ennemy.ressources.mana = newRessource("mana", 10, 10)

    ennemy:addAction(actions.Walk({range=2}))
    ennemy:addAction(actions.MeleeAttack({damage = 2}))
    ennemy:addAction(actions.MagicMissile({range = 3,damage = 3}))
    ennemy:addAction(actions.Heal({healAmout = 1, cost = {newRessource("mana", 1)}}))


    ennemy:initEntity()
    return ennemy
  end
}

function spawn(type)
  if types[type] then
    local ennemy = types[type]()
    ennemy.i, ennemy.j = math.random(8, mapWidth), math.random(8, mapHeight)
    ennemy:initEntity()
    return ennemy
  end
end

function rollDice()
  
  table.insert(game.nextTurns, actionTypesKeys[math.random(#actionTypesKeys)])
  nextTurnUI:updateTurns()
  -- diceEntity = {
  --   x = 0, y=0, z = 0, f = 2, timer = 0, bounceH = 300,
  --   n = 1, rolling = true,
  --   angle = 0, speed = 500,
  --   update = function(self, dt)
  --     if self.rolling then
  --       self.timer = self.timer + dt
  --       oldZ = self.z
  --       self.z = self.bounceH*math.abs(math.sin(self.timer*math.pi/self.f))
  --       self.x, self.y = self.x + self.speed*math.cos(self.angle)*dt, self.y + self.speed*math.sin(self.angle)*dt
  --       if oldZ > 10 and self.z < 10 then
  --         self.angle = math.random()*math.pi*2
  --         self.bounceH = self.bounceH/3
  --         if self.bounceH < 50 then
  --           self.rolling = false
  --           self.actionType = actionTypesKeys[math.random(#actionTypesKeys)]
  --         end
  --       end
  --       if math.random() > .5 then
  --         self.n = self.n%#fuzzyDicesImages + 1
  --       end
  --       if self.x < -.25*width or self.y < -.25*height or self.x > .25*width or self.y > .25*height then
  --         self.angle = math.angle(self.x, self.y, 0, 0)
  --       end
  --     else
  --       if self.angle > 0 then
  --         self.angle = .9*self.angle
  --         if self.angle < .1 then self.angle = 0 end
  --       end
  --       if self.x ~= diceDestination.x and self.y~=diceDestination.y then
  --         if math.dist(self.x, self.y, diceDestination.x, diceDestination.y) >= self.speed * dt then 
  --           local angle = math.angle(self.x, self.y, diceDestination.x, diceDestination.y)
  --           self.x = self.x + self.speed * dt * math.cos(angle)
  --           self.y = self.y + self.speed * dt * math.sin(angle)
  --         else 
  --           self.x = diceDestination.x
  --           self.y = diceDestination.y
  --           if #game.nextTurns < game.maxPrerolledTurns then
  --             table.insert(game.nextTurns, self.actionType)
  --             nextTurnUI:updateTurns()
  --           end
  --           self.terminated = true
  --         end
  --       end
  --     end
  --   end,
  --   draw = function (self)
  --     if self.rolling then
  --       love.graphics.setColor(1, 1, 1)
  --       local image = fuzzyDicesImages[self.n]
  --       local w, h = .5*image:getWidth(), .5*image:getHeight()
  --       love.graphics.push()
  --       love.graphics.setColor(0, 0, 0, .1)
  --       love.graphics.translate(self.x+.5*w, self.y+.5*h)
  --       love.graphics.rotate(math.random()*.5)
  --       love.graphics.translate(-.5*w, -.5*h)
  --       love.graphics.draw(image, 0, 0, 0, .5, .5)
  --       love.graphics.pop()
  --       love.graphics.setColor(1, 1, 1)
  --       love.graphics.translate(self.x+.5*w, self.y-self.z+.5*h)
  --       love.graphics.rotate(math.random()*.5)
  --       love.graphics.translate(-.5*w, -.5*h)
  --       love.graphics.draw(image, 0, 0, 0, .5, .5)
  --     else
  --       local w, h = 80/diceImg:getWidth(), 80/diceImg:getHeight()
  --       love.graphics.push()
  --       love.graphics.setColor(0, 0, 0, .1)
  --       love.graphics.translate(self.x+.5*w, self.y+10+.5*h)
  --       love.graphics.rotate(self.angle)
  --       love.graphics.translate(-.5*w, -.5*h)
  --       love.graphics.draw(diceImg, 0, 0, 0, w, h)
  --       love.graphics.pop()
  --       local currImg = actionTypes[self.actionType].img
  --       love.graphics.setColor(1, 1, 1)
  --       love.graphics.draw(diceImg, self.x, self.y, self.angle, w, h)
  --       love.graphics.draw(currImg, self.x, self.y, self.angle, w, h)
  --     end
  --   end,
  --   roll = function (self)
  --     self.rolling = true
  --     self.bounceH = 300
  --   end,
  -- }
  -- table.insert(entities, diceEntity)
end


function love.mousemoved(x, y, dx, dy)
  local mouseoverUI = UIMouseMoved(x, y, dx, dy)
  if not mouseoverUI then
    
  end
end

function love.mousepressed(x, y, button, isTouch)
  local press = UIMousePress(x, y , button)
  if not press then
    local i, j = screenToGrid(x, y)
    if map[i] and map[i][j] and map[i][j] > 0 then
      if selectedAction then
        if selectedAction:try({i=i, j=j}) then
          game:endTurn()
        end
      end
      selectedAction = nil
    end
  end
end

function love.mousereleased(x, y, button, isTouch)
  UIMouseRelease(x, y, button)
end

function love.keypressed(key, scancode, isrepeat)
  if not victory.hidden then game:start() end
  if not defeat.hidden then ShowMenu() end
  if love.keyboard.isDown("lctrl") and love.keyboard.isDown("rctrl") then
   victory.hidden = false
  end
  if key == "escape" then
    if MenuScreen.hidden and mode == "normal" then
      ShowMenu()
    else
      love.event.quit()
    end
  end
  if player and player.actions then
    if player.actions[tonumber(key)] and player.actions[tonumber(key)].actionType == game.nextTurns[1] then
      selectedAction = player.actions[tonumber(key)]
    elseif player.actions[tonumber(key)] and player.actions[tonumber(key)].actionType ~= game.nextTurns[1] and not mapHidden then
      audioManager:playSound(audioManager.sounds.wrong)
    elseif key == "space" then
      audioManager:playSound(audioManager.sounds.click)
      game:endTurn()
    end
  end
end

function newAnimation(image, width, height, duration, w, h)
  local animation = {}
  animation.spriteSheet = image;
  animation.quads = {};
  animation.scale = {x = w/width, y = h/height} or {x=1, y=1}
  for y = 0, image:getHeight() - height, height do
    for x = 0, image:getWidth() - width, width do
      table.insert(animation.quads, love.graphics.newQuad(x, y, width, height, image:getDimensions()))
    end
  end
  
  animation.duration = duration or 1
  animation.currentTime = 0
  
  animation.update = function (self, dt)
    self.currentTime = self.currentTime + dt
    if self.currentTime >= self.duration then
      self.currentTime = self.currentTime - self.duration
    end
  end
  
  animation.draw = function (self)
    local spriteNum = math.floor(self.currentTime / self.duration * #self.quads) + 1
    love.graphics.draw(self.spriteSheet, self.quads[spriteNum], -.5*width*self.scale.x, -.5*height*self.scale.y, 0, self.scale.x, self.scale.y)
  end
  return animation
end

function getEntityOn(i, j)
  for e, entity in pairs(entities) do
    if entity.i and entity.i == i and entity.j and entity.j == j then return entity end
  end
end


function tests()
  testLivingEntityRessource()
  testActions()
end

audioManager = {
  musics = {},
  musicVolume = .05, mute = false,
  
  loadMusic = function(self, name, path)
    self.musics[name] = love.audio.newSource( path, 'static' )
  end,

  toggleMute = function(self, forced)
    self.mute = forced or not self.mute
    if self.mute then
      love.audio.pause()
    elseif self.music then
      self.music:play()
    end
  end,
  changeMusicVolume = function (self, newVolume)
    self.musicVolume = newVolume
    if self.music then
      self.music:setVolume(self.musicVolume)
    end
  end,
  
  playMusic = function (self, music)
    if self.music == music then return end
    if self.music then
      self.music:stop()
      self.music:seek(0)
    end
    self.music = music
    self.music:play()
    if self.mute then self.music:pause() end
    self.music:setVolume(self.musicVolume)
    self.music:setLooping(true)
  end,
  
  sounds = { },

  SEVolume = 1, muteSE = false,
  playingSounds = {},
  
  loadSoundEffect = function(self, name, path)
    self.sounds[name] = love.audio.newSource( path, 'static' )
  end,

  toggleMuteSE = function(self, forced)
    self.muteSE = forced or not self.muteSE
    for s, sound in pairs(self.playingSounds) do
      sound:stop()
    end
    self.playingSounds = {}
  end,
  
  changeSEVolume = function (self, newVolume)
    self.SEVolume = newVolume
    for s, sound in pairs(self.playingSounds) do
      sound:setVolume(newVolume)
    end
  end,
  
  playSound = function (self, sound)
    if self.muteSE then return end
    local clone = sound:clone()
    clone:setVolume(self.SEVolume)
    table.insert(self.playingSounds, clone)
    clone:play()
    self:cleanPlayingSounds()
    return clone
  end,
  
  cleanPlayingSounds = function (self)
    for s = #self.playingSounds, 1, -1 do
      if not self.playingSounds[s]:isPlaying() then
        table.remove(self.playingSounds, s)
      end
    end
  end
}


function setupUpgrades()
  upgradeText = ""
  upgrades = {
    {player.actions[2], "range", 1},
    {player.actions[3], "healAmout", 1},
    {player.actions[4], "damage", 5},
    {player.actions[4], "range", 5},
    {player.actions[1], "range", 5},
    {player.ressources.life, "max", 59},
    {player.ressources.mana, "max", 19}
  }
  upgradeWeightSum = 0
  for u, upgrade in pairs(upgrades) do
    upgradeWeightSum = upgradeWeightSum + upgrade[3]
  end
end

function upgradePlayer()
  local roll = math.random(upgradeWeightSum)
  for u, upgrade in pairs(upgrades) do
    roll = roll - upgrade[3]
    if roll < 0 then
      upgradeText = upgrade[1].name .." gained 1 " .. upgrade[2] .."\n" .. upgradeText
      upgrade[1][upgrade[2]] = upgrade[1][upgrade[2]] + 1
      break
    end
  end
end