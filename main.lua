require "base"
require "ui"
require "map"
require "entity"
require "action"

function projectSetup()
  love.graphics.setBackgroundColor(.3, .3, .3)
  love.graphics.setNewFont("src/fonts/Quantum.otf", 25)
  GMTKScreen = {
    image = love.graphics.newImage("src/img/gmtkLogo.jpg"), timeLeft = 3,
    x=-width/2, y=-height/2,
    draw = function (self)
      love.graphics.setColor(1, 1, 1, self.timeLeft)
      love.graphics.translate(self.x, self.y)
      love.graphics.draw(self.image, 0, 0, 0, width/self.image:getWidth(), height/self.image:getHeight())
    end,
    onTermination = function ()
      ShowMenu()
    end
  }
  table.insert(particuleEffects, GMTKScreen)

  game = {
    gameState = "unlaunched",
    nTurn = 1,
    maxPrerolledTurns = 5,
    nextTurns = {},
    start = function(self)
      self.nTurn = 1
      self.nextTurns = {"move", "move", "move"}

      self:fillTurns()

      fillMap()

      player = applyParams(newLivingEntity(), {i = 3, j=3, w=32, h=32, spriteSet = {path = "src/img/sprites/oldHero.png", width = 16, height = 16}})
      player.ressources.life = newRessource("life", 10, 10)
      player.ressources.mana = newRessource("mana", 3, 3)
      player:addAction(actions.Walk({range=2}))
      player:addAction(actions.MeleeAttack())
      player:addAction(actions.Heal())
      player:addAction(actions.MagicMissile())
      player:initEntity()
      
      volcano = applyParams(newEntity(), {x=-width/2, h=-height/2, w=258, h=258, spriteSet = {path = "src/img/sprites/VolcanoTile.png", width = 258, height = 258, duration = 2.3}})
      animation = newAnimation(love.graphics.newImage("src/img/sprites/VolcanoTile.png"), 258, 258, 2.3, 258, 258)
      volcano:initEntity()
    
    
      
      ennemy = applyParams(newLivingEntity(), {i = 10, j=10, w=32, h=32, color = {1, 0, 0}, spriteSet = {path = "src/img/sprites/oldHero.png", width = 16, height = 16}})
      ennemy.ressources.life = newRessource("life", 10, 10)
      ennemy:addAction(actions.Walk({range=2}))
      ennemy:addAction(actions.MeleeAttack())
      ennemy:addAction(actions.Heal())
      ennemy:initEntity()


    end,
    finish = function (self)
      for e, entity in pairs(entities) do
        entity.terminated = true
      end
    end,
    fillTurns = function (self)
      while #self.nextTurns < self.maxPrerolledTurns do
        table.insert(self.nextTurns, actionTypesKeys[math.random(#actionTypesKeys)])
      end
    end,
    endTurn = function (self)
      self:playIAs()
      if player:isDead() then
          table.insert(uis, {
            x = 0, y = 0,
            draw = function ()
              love.graphics.push()
              love.graphics.origin()
              love.graphics.translate(.5*width, .5*height)
              victoire = victoire or {s=30}
              love.graphics.setColor(1, 0, 0)
              love.graphics.polygon("fill",
              victoire.s,  victoire.s,
              -victoire.s,  victoire.s,
              -1.5*victoire.s, 0,
              -victoire.s, -victoire.s,
              victoire.s, -victoire.s,
              1.5*victoire.s, 0)
              victoire.s = math.min(victoire.s + 1, 120)
              love.graphics.setColor(.2, .2, .2)
              local text = "Defaite"
              love.graphics.print(text, -.5*love.graphics.getFont():getWidth(text),-.5*love.graphics.getFont():getHeight())
              love.graphics.pop()
            end
          })
      end
      table.remove(self.nextTurns, 1)
      self:fillTurns()
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
        table.insert(uis, {
          x = 0, y = 0,
          draw = function ()
            love.graphics.push()
            love.graphics.origin()
            love.graphics.translate(.5*width, .5*height)
            victoire = victoire or {s=30}
            love.graphics.setColor(.73, .5, .4)
            love.graphics.polygon("fill",
            victoire.s,  victoire.s,
            -victoire.s,  victoire.s,
            -1.5*victoire.s, 0,
            -victoire.s, -victoire.s,
            victoire.s, -victoire.s,
            1.5*victoire.s, 0)
            victoire.s = math.min(victoire.s + 1, 120)
            love.graphics.setColor(.2, .8, .4)
            local text = "Victoire"
            love.graphics.print(text, -.5*love.graphics.getFont():getWidth(text),-.5*love.graphics.getFont():getHeight())
            love.graphics.pop()
          end
        })
      end
    end
  }

  setupMap()
  setupMapView()
  setupTileset()
  setupUIs()
  for i, ui in pairs(uis) do
    ui.hidden = true
  end

  
  ShowMenu = function ()
    for i, ui in pairs(uis) do
      ui.hidden = true
    end
    mapHidden = true
    ExitButton.hidden = false
    OptionButton.hidden = false
    StartButton.hidden = false
    audioManagerUI.hidden = false
    game:finish()
    audioManager:playMusic(audioManager.musics.mainTheme)
  end
  HideMenu = function ()
    for i, ui in pairs(uis) do
      ui.hidden = false
    end
    ExitButton.hidden = true
    OptionButton.hidden = true
    StartButton.hidden = true
    mapHidden = false
  end
end

function setupUIs()
  menuRadial = { -- Dedicace Sobroniel pour le nom de variable
    x = 0, y = height*.8,w=width, h = .2*height,
    color = {.1, .1, .1},
    children = {},
    draw = function (self)
      love.graphics.setColor(self.color)
      love.graphics.rectangle("fill", 0, 0, self.w, self.h)
    end
  }
  table.insert(uis, menuRadial)

  playerActionsUIX = 400
  statsUI = {
    backgroundColor = {.5, .2, .2}, textColor = {.3, .7, .7},
    x = 10, y = 10, w = playerActionsUIX - 20, h = .2*height,
    draw = function (self)
      love.graphics.setColor(self.backgroundColor)
      love.graphics.rectangle("fill", 0, 0, self.w, self.h)
      love.graphics.setColor(self.textColor)
      if player and player.ressources then
        local y = 0
        for r, ressource in pairs(player.ressources) do
          love.graphics.print(ressource.name.." "..ressource.quantity.."/"..ressource.max, 0, y)
          y = y + 15
        end
      end
    end
  }
  table.insert(menuRadial.children, statsUI)

  playerActionsUI = {
    x = playerActionsUIX, y = 10,w=width-playerActionsUIX-170, h = .2*height-10,
    color = {.1, .1, .1},
    draw = function (self)
      if player and #player.actions>0 and #self.children == 0 then self:loadPlayerActions() end
      love.graphics.setColor(self.color)
      love.graphics.rectangle("fill", 0, 0, self.w, self.h)
    end,
    children = {},
    loadPlayerActions = function (self)
      if not player or not player.actions then return end
      self.children = {}
      x = 10
      local child
      for a, action in pairs(player.actions) do
        child = {
          x = x, y = 10, w = 150, h = 150,
          draw = function (self)
            love.graphics.setColor(.2, .2, .2)
            love.graphics.rectangle("fill", 0, 0, self.w, self.h)
            love.graphics.setColor(1, 1, 1)
            love.graphics.print(action.name, 5, 5)
            love.graphics.print(action.actionType, 135, 135)
            if action.actionType ~= game.nextTurns[1] then
              love.graphics.setColor(1, 0, 0, .1)
              love.graphics.rectangle("fill", 0, 0, self.w, self.h)
            end
          end,
          tooltip = {w = 200, h=200, backgroundColor = {.2, .2, .2}},
          drawTooltip = function (self)
            love.graphics.origin()
            love.graphics.translate(love.mouse.getX(), love.mouse.getY() - self.tooltip.h)
            love.graphics.setColor(self.tooltip.backgroundColor)
            love.graphics.rectangle("fill", 0, 0, self.tooltip.w, self.tooltip.h)
            love.graphics.setColor(1, 1, 1)
            love.graphics.print("name:"..action.name, 10, 10)
            love.graphics.print("range:"..action.range, 10, 25)
            love.graphics.print("can be used on oneself:"..(action.usableOnSelf and "Yes" or "No"), 10, 40)
            love.graphics.print("costs: "..(#action.cost==0 and "none" or ""), 10, 55)
            y =  55
            for r, ressource in pairs(action.cost) do
              if player:isAvailable(ressource) then
                love.graphics.setColor(0, 1, 0)
              else
                love.graphics.setColor(1, 0, 0)
              end
              love.graphics.print(ressource.quantity.." "..ressource.name, .6*self.tooltip.w, y)
              y = y + 15
            end
            y = y + 15
            love.graphics.setColor(1, 1, 1)
            love.graphics.print("type of action: "..action.actionType, 10, y)
            y = y + 15
            love.graphics.print("shortcut: " .. a .. " key", 10, y)
            y = y + 15
            love.graphics.printf(action:getDescription(), 10, y, self.tooltip.w - 20)
          end,
          onClick = function (self)
            if action.actionType == game.nextTurns[1] then
              selectedAction = action
            end
          end
        }
        x = x + 170
        table.insert(self.children, child)
      end
    end
  }
  table.insert(menuRadial.children, playerActionsUI)

  endTurnButton = {
    x = width - 170, y = 20, w = 150, h = 150,
    backgroundColor = {.2, .2, .2}, textColor = {1, 1, 1}, text = "ENDTURN", textX = .5*150 - .5*love.graphics.getFont():getWidth("ENDTURN"),
    draw = function (self)
      love.graphics.setColor(self.backgroundColor)
      love.graphics.rectangle("fill", 0, 0, self.w, self.h)
      love.graphics.setColor(self.textColor)
      love.graphics.print(self.text, self.textX, .45*self.h)
    end,
    tooltip = {w = 200, h=200, backgroundColor = {.2, .2, .2}},
    drawTooltip = function (self)
      love.graphics.origin()
      love.graphics.translate(love.mouse.getX() - self.tooltip.w, love.mouse.getY() - self.tooltip.h)
      love.graphics.setColor(self.tooltip.backgroundColor)
      love.graphics.rectangle("fill", 0, 0, self.tooltip.w, self.tooltip.h)
      love.graphics.setColor(1, 1, 1)
      love.graphics.print("shortcut: spacebar", 10, 10)
      love.graphics.printf("End your turn without using your action. Be careful the ennemies will still use theirs if they can!", 10, 50, self.tooltip.w-20)
    end,
    onClick = function(self)
      game:endTurn()
    end
  }
  table.insert(menuRadial.children, endTurnButton)
  actionOverlay = {
    draw = function (self)
      if selectedAction and player then
        love.graphics.setColor(1, 1, 1, .1)
        local dx, dy = math.floor(-zoomX*(mapI%1)*tileSize), math.floor(-zoomY*(mapJ%1)*tileSize)
        love.graphics.translate(mapX+dx, mapY+dy)
        for i=0, tilesDisplayWidth-1 do
          for j=0, tilesDisplayHeight-1 do
            if map[i] and map[i][j] and map[i][j]>0 then
              if (manhattanDistance(player, {i=i, j=j})==0 and selectedAction.usableOnSelf) or (manhattanDistance(player, {i=i, j=j})>0 and manhattanDistance(player, {i=i, j=j}) <= selectedAction.range) then
                love.graphics.rectangle("fill", (i-1)*zoomX*tileSize, (j-1)*zoomY*tileSize, zoomX*tileSize, zoomY*tileSize)
              end
            end
          end
        end
      end
    end
  }
  table.insert(uis, actionOverlay)

  nextTurnUIW = 600
  nextTurnUI = {
    x= .5*(width-nextTurnUIW), y = 0,w = nextTurnUIW, h = 100,
    backgroundColor = {.1, .1, .1},
    draw = function(self)
      love.graphics.setColor(self.backgroundColor)
      love.graphics.rectangle("fill", 0, 0, self.w, self.h)
      for n, turn in pairs(game.nextTurns) do
        love.graphics.setColor(.4, .3, .2)
        love.graphics.print(turn, (n-.5)*(nextTurnUIW-20)/5, 40)
      end
    end
  }
  table.insert(uis, nextTurnUI)

  
  local image = love.graphics.newImage("src/img/Options/EXIT.png")
  local subImage = {x = 23, y= 54, w=85, h=22}
  local quad = love.graphics.newQuad(subImage.x, subImage.y, subImage.w, subImage.h, image)
  ExitButton = {
    x = .5*(width - subImage.w), y = .5*height -3* subImage.h,
    w = subImage.w, h = subImage.h, image = image, quad = quad,
    hidden = true,
    draw = function (self)
      love.graphics.setColor(1, 1, 1)
      love.graphics.draw(self.image, self.quad, 0, 0)
    end,
    onClick = function (self)
      love.event.quit()
    end
  }
  table.insert(uis, ExitButton)

  local image = love.graphics.newImage("src/img/Options/options.png")
  local subImage = {x = 23, y= 54, w=85, h=22}
  local quad = love.graphics.newQuad(subImage.x, subImage.y, subImage.w, subImage.h, image)
  OptionButton = {
    x = .5*(width - subImage.w), y = .5*height,
    w = subImage.w, h = subImage.h, image = image, quad = quad,
    hidden = true,
    draw = function (self)
      love.graphics.setColor(1, 1, 1)
      love.graphics.draw(self.image, self.quad, 0, 0)
    end,
    onClick = function (self)
      
    end
  }
  table.insert(uis, OptionButton)

  local image = love.graphics.newImage("src/img/Options/start.png")
  local subImage = {x = 23, y= 54, w=85, h=22}
  local quad = love.graphics.newQuad(subImage.x, subImage.y, subImage.w, subImage.h, image)
  StartButton = {
    x = .5*(width - subImage.w), y = .5*height +3* subImage.h,
    w = subImage.w, h = subImage.h, image = image, quad = quad,
    hidden = true,
    draw = function (self)
      love.graphics.setColor(1, 1, 1)
      love.graphics.draw(self.image, self.quad, 0, 0)
    end,
    onClick = function (self)
      HideMenu()
      game:start()
      audioManager:playMusic(audioManager.musics.prairieTheme)
    end
  }
  table.insert(uis, StartButton)



  audioManagerUI = {
    x = 0, y = 0, w = 100, h= 350,
    backgroundColor = {.2, .2, .2},
    children = {
      {
        x = 10, y = 10, w = 80, h = 20,
        draw = function (self)
          love.graphics.setColor(1, 1, 1)
          love.graphics.print("Music:")
        end
      },
        --muteMusicButton
      {
        x = 10, y = 40, 
        w = 50, h = 50,
        draw = function (self)
          love.graphics.setColor(1, 1, 1)
          love.graphics.rectangle("line", 0, 0, self.w, self.h)
          if audioManager.mute then
            love.graphics.print("mute", 5, 5)
          else
            love.graphics.print("unmute", 5, 5)
          end
        end,
        onClick = function (self)
          audioManager:toggleMute()
          print(self.px, self.py)
        end
      },
      --slider
      {
        x = 10, y = 110,
        w = 80, h = 50,
        draw = function (self)
          love.graphics.setColor(1, 1, 1)
          love.graphics.rectangle("line", 0, .5*self.h, self.w, 2)
          love.graphics.rectangle("line", audioManager.musicVolume*self.w, 0, .1*self.w, self.h)
        end,
        onClick = function (self)
          if self.px and self.py then
            audioManager:changeMusicVolume(self.px/self.w)
          end
        end
      },
      {
        x = 10, y = 180, w = 80, h = 20,
        draw = function (self)
          love.graphics.setColor(1, 1, 1)
          love.graphics.print("Sound effects:")
        end
      },
        --muteMusicButton
      {
        x = 10, y = 220, 
        w = 50, h = 50,
        draw = function (self)
          love.graphics.setColor(1, 1, 1)
          love.graphics.rectangle("line", 0, 0, self.w, self.h)
          if audioManager.muteSE then
            love.graphics.print("mute", 5, 5)
          else
            love.graphics.print("unmute", 5, 5)
    end
        end,
        onClick = function (self)
          audioManager:toggleMuteSE()
          print(self.px, self.py)
  end
      },
      --slider Effects
      {
        x = 10, y = 290,
        w = 80, h = 50,
        draw = function (self)
          love.graphics.setColor(1, 1, 1)
          love.graphics.rectangle("line", 0, .5*self.h, self.w, 2)
          love.graphics.rectangle("line", audioManager.SEVolume*self.w, 0, .1*self.w, self.h)
        end,
        onClick = function (self)
          if self.px and self.py then
            audioManager:changeSEVolume(self.px/self.w)
    end
  end
      }
    },
    draw = function (self)
      love.graphics.setColor(self.backgroundColor)
      love.graphics.rectangle("fill", 0, 0, self.w, self.h)
  end
  }
  table.insert(uis, audioManagerUI)
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
  --https://www.youtube.com/watch?v=79DijItQXMM
  if key == "escape" then
    ShowMenu()
    print("...")
  end
  if player and player.actions then
    if player.actions[tonumber(key)] and player.actions[tonumber(key)].actionType == game.nextTurns[1] then
      selectedAction = player.actions[tonumber(key)]
    elseif key == "space" then
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
  musics = {
    mainTheme = love.audio.newSource( 'src/snd/test3.mp3', 'static' ),
    prairieTheme = love.audio.newSource( 'src/snd/prairie.mp3', 'static' )
  },
  musicVolume = .05, mute = false, SEVolume = .1, muteSE = false,
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
  toggleMuteSE = function(self, forced)

  end,
  changeSEVolume = function (self, newVolume)

  end,
  playMusic = function (self, music)
    if self.music == music then return end
    if self.music then
      self.music:stop()
      self.music:seek(0)
    end
    self.music = music
    self.music:play()
    self.music:setVolume(self.musicVolume)
    self.music:setLooping(true)
  end
}
