function setupUIs()
  MenuScreen = {
    x=0, y=0, w = width, h = height,
    children = {},
    hidden = true,
    draw = function () end
  }
  table.insert(uis, MenuScreen)
  GameScreen = {
    x=0, y=0, w = width, h = height,
    children = {},
    hidden = true,
    draw = function () end
  }
  table.insert(uis, GameScreen)

  victory = {
    x = .5*width-120, y = .5*height-120, w=  240, h= 240,hidden = true,
    draw = function ()
      love.graphics.push()
      love.graphics.origin()
      love.graphics.translate(.5*width, .5*height)
      love.graphics.setColor(.73, .5, .4)
      love.graphics.polygon("fill",
      120,  120,
      -120,  120,
      -1.5*120, 0,
      -120, -120,
      120, -120,
      1.5*120, 0)
      love.graphics.setColor(.2, .8, .4)
      local text = "Victory"
      love.graphics.print(text.."\nlevel "..game.level, -.5*love.graphics.getFont():getWidth(text),-.5*love.graphics.getFont():getHeight())
      love.graphics.pop()
    end,
    onClick = function()
      game:start()
    end
  }
  table.insert(GameScreen.children, victory)
  defeat = {
    x = .5*width-120, y = .5*height-120, w=  240, h= 240,hidden = true,
    draw = function ()
      love.graphics.push()
      love.graphics.origin()
      love.graphics.translate(.5*width, .5*height)
      love.graphics.setColor(1, 0, 0)
      love.graphics.polygon("fill",
      120,  120,
      -120,  120,
      -1.5*120, 0,
      -120, -120,
      120, -120,
      1.5*120, 0)
      love.graphics.setColor(.2, .2, .2)
      local text = "Defeat"
      love.graphics.print(text, -.5*love.graphics.getFont():getWidth(text),-.5*love.graphics.getFont():getHeight())
      love.graphics.pop()
    end,
    onClick =function()
      
      ShowMenu()
    end
  }
  table.insert(GameScreen.children, defeat)

  -- Dedicace Sobroniel pour le nom de variable
  menuRadial = {
    x = 0, y = height*.8,w=width, h = .2*height,
    color = {.1, .1, .1},
    children = {},
    draw = function (self)
      love.graphics.setColor(self.color)
      love.graphics.rectangle("fill", 0, 0, self.w, self.h)
    end
  }
  table.insert(GameScreen.children, menuRadial)
  
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
          local t = ressource.name.." "..ressource.quantity.." "
          love.graphics.print(ressource.name.." "..ressource.quantity.."   "..ressource.max, 0, y)
          local sx, sy = font:getWidth(t),  font:getHeight()/2
          love.graphics.line(sx+3, y-5+sy, sx-3, y + 5+sy)
          y = y + 25
        end
        love.graphics.printf(upgradeText, 5, y, self.w-10)
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
            love.graphics.setColor({1, 1, 1, .1})
            love.graphics.rectangle("line", 5, 5, self.w-10, self.h-10)
            love.graphics.setColor(1, 1, 1)
            love.graphics.printf(action.name, 5, 5, self.w-10)
            local x, y = self.w-font:getWidth(action.actionType)-10, self.h-font:getHeight()-10
            love.graphics.print(action.actionType, x, y)
            local image= actionTypes[action.actionType].img
            local size = self.w
            love.graphics.draw(image, 0, 0, 0, size/image:getWidth(), size/image:getHeight())
            if action.actionType ~= game.nextTurns[1] then
              love.graphics.setColor(1, 0, 0, .1)
              love.graphics.rectangle("fill", 0, 0, self.w, self.h)
            end
          end,
          tooltip = {w = 600, h=300, backgroundColor = {.2, .2, .2}},
          drawTooltip = function (self)
            love.graphics.origin()
            love.graphics.print("?", love.mouse.getX()+10, love.mouse.getY()+10)
            love.graphics.translate(love.mouse.getX()-.5*self.tooltip.w, love.mouse.getY() - self.tooltip.h)
            love.graphics.setColor(self.tooltip.backgroundColor)
            love.graphics.rectangle("fill", 0, 0, self.tooltip.w, self.tooltip.h)
            love.graphics.setColor({1, 1, 1, .1})
            love.graphics.rectangle("line", 5, 5, self.tooltip.w-10, self.tooltip.h-10)
            love.graphics.setColor(1, 1, 1)
            local interLigne = 20
            local y =10
            love.graphics.print("name:"..action.name, 10, y)
            y = y  + interLigne
            love.graphics.print("range:"..action.range, 10, y)
            y = y  + interLigne
            love.graphics.print("can be used on oneself:"..(action.usableOnSelf and "Yes" or "No"), 10, y)
            y = y  + interLigne
            love.graphics.print("costs: "..(#action.cost==0 and "none" or ""), 10, y)
            for r, ressource in pairs(action.cost) do
              if player:isAvailable(ressource) then
                love.graphics.setColor(0, 1, 0)
              else
                love.graphics.setColor(1, 0, 0)
              end
              love.graphics.print(ressource.quantity.." "..ressource.name, .6*self.tooltip.w, y)
              y = y + interLigne
            end
            y = y + interLigne
            love.graphics.setColor(1, 1, 1)
            love.graphics.print("type of action: "..action.actionType, 10, y)
            y = y + interLigne
            love.graphics.print("shortcut: " .. a .. " key", 10, y)
            y = y + interLigne
            y = y + interLigne
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
      love.graphics.setColor({1, 1, 1, .1})
      love.graphics.rectangle("line", 5, 5, self.w-10, self.h-10)
      love.graphics.setColor(self.textColor)
      love.graphics.print(self.text, self.textX, .45*self.h)
    end,
    tooltip = {w = 300, h=200, backgroundColor = {.2, .2, .2}},
    drawTooltip = function (self)
      love.graphics.origin()
      love.graphics.print("?", love.mouse.getX()+10, love.mouse.getY()+10)
      love.graphics.translate(love.mouse.getX() - self.tooltip.w, love.mouse.getY() - self.tooltip.h)
      love.graphics.setColor(self.tooltip.backgroundColor)
      love.graphics.rectangle("fill", 0, 0, self.tooltip.w, self.tooltip.h)
      love.graphics.setColor({1, 1, 1, .1})
      love.graphics.rectangle("line", 5, 5, self.tooltip.w-10, self.tooltip.h-10)
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
  table.insert(GameScreen.children, actionOverlay)
  
  nextTurnUIW = 500
  nextTurnUI = {
    x= .5*(width-nextTurnUIW), y = 0,w = nextTurnUIW, h = 100,
    backgroundColor = {.1, .1, .1},
    children = {},
    draw = function(self)
      love.graphics.setColor(self.backgroundColor)
      love.graphics.rectangle("fill", 0, 0, self.w, self.h)
    end,
    updateTurns = function (self)
      self.children = {}
      for n, turn in pairs(game.nextTurns) do
        local child = {
          x = (n-1)*100, y = 0, w = 100, h = 100,
          draw = function (self)
            love.graphics.setColor({.1, .1, .1})
            love.graphics.rectangle("fill", 0, 0, self.w, self.h)
            local currImg = actionTypes[turn].img
            love.graphics.setColor(1,1,1)
            
            love.graphics.draw(diceImg, 0, 0, 0, self.w/diceImg:getWidth(), self.h/diceImg:getHeight())
            love.graphics.draw(currImg, 0, 0, 0, self.h/currImg:getWidth(), self.h/currImg:getHeight())
            if n == 1 then
              love.graphics.rectangle("line", 0, 0, self.w, self.h)
              love.graphics.polygon("fill", .5*self.w, .9*self.h, .4*self.w, self.h, .6*self.w, self.h)
            end
          end
        }
        if n == 1 then
          child.x = child.x - 20
          child.w = child.w + 20
          child.h = child.h + 20
        end
        table.insert(self.children, child)
      end
    end
  }
  table.insert(GameScreen.children, nextTurnUI)
  
  
  local image = love.graphics.newImage("src/img/Options/EXIT.png")
  local subImage = {x = 23, y= 54, w=85, h=22}
  local quad = love.graphics.newQuad(subImage.x, subImage.y, subImage.w, subImage.h, image)
  ExitButton = {
    x = (width - 5*subImage.w), y = 0,
    w = 5*subImage.w, h = 5*subImage.h, image = image, quad = quad,
    draw = function (self)
      love.graphics.setColor(1, 1, 1)
      love.graphics.draw(self.image, self.quad, 0, 0, 0, self.w/subImage.w, self.h/subImage.h)
    end,
    onClick = function (self)
      love.event.quit()
    end
  }
  table.insert(MenuScreen.children, ExitButton)
  
  local image = love.graphics.newImage("src/img/Options/options.png")
  local subImage = {x = 23, y= 54, w=85, h=22}
  local quad = love.graphics.newQuad(subImage.x, subImage.y, subImage.w, subImage.h, image)
  OptionButton = {
    x = .5*(width - subImage.w), y = .5*height,
    w = subImage.w, h = subImage.h, image = image, quad = quad,
    draw = function (self)
      love.graphics.setColor(1, 1, 1)
      love.graphics.draw(self.image, self.quad, 0, 0)
    end,
    onClick = function (self)
      
    end
  }
  -- table.insert(MenuScreen.children, OptionButton)
  
  local image = love.graphics.newImage("src/img/Options/start.png")
  local subImage = {x = 23, y= 54, w=85, h=22}
  local quad = love.graphics.newQuad(subImage.x, subImage.y, subImage.w, subImage.h, image)
  StartButton = {
    x = .8*(width - subImage.w), y = .8*height +3* subImage.h,
    w = 5*subImage.w, h = 5*subImage.h, image = image, quad = quad,
    draw = function (self)
      love.graphics.setColor(1, 1, 1)
      love.graphics.draw(self.image, self.quad, 0, 0, 0, self.w/subImage.w, self.h/subImage.h)
    end,
    onClick = function (self)
      HideMenu()
      game:start()
      audioManager:playMusic(audioManager.musics.prairieTheme)
    end
  }
  table.insert(MenuScreen.children, StartButton)
  
  
  
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
  table.insert(GameScreen.children, audioManagerUI)
  table.insert(MenuScreen.children, audioManagerUI)


end

  
function ShowMenu()
  MenuScreen.hidden = false
  GameScreen.hidden = true
  mapHidden = true
  game:finish()
  audioManager:playMusic(audioManager.musics.mainTheme)
  mouseover = nil
end

function HideMenu()
  MenuScreen.hidden = true
  GameScreen.hidden = false
  mapHidden = false
end


--uiMockup

  -- testUI = {
  --   x= 100, y=100,
  --   w = 300, h=300,
  --  children = {
  --    {
  --      x = 10, y =10, w=30, h=30,
  --      draw = function (self)
  --        love.graphics.setColor(0, 0, 0)
  --        love.graphics.rectangle("fill", 0, 0, self.w, self.h)
  --      end,
  --      onClick = function (self)
  --        print("testUI child click!")
  --      end,
  --      onPress = function (self)
  --        print("testUI child press!")
  --      end
  --    }
  --  },
  --   onClick = function (self)
  --     print("testUI parent click!")
  --   end,
  --   onPress = function (self)
  --     print("testUI parent press!")
  --   end,
  --   draw = function (self)
  --     love.graphics.setColor(0, 1, 0)
  --     love.graphics.rectangle("fill", 0, 0, self.w, self.h)
  --   end
  -- }
  -- table.insert(uis, testUI)
