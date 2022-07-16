function newEntity(params)
    local entity = {}
    
    entity.i, entity.j = nil      -- board coordinates
    entity.x, entity.y = 0, 0       -- screen coordinates (can varies from linear interpolation of coordinates during animations)
    entity.snappingSpeed = 300
    entity.w, entity.h = tileSize

    entity.updates = {}
    entity.update = function (self, dt)
        for u, updateFunction in pairs(self.updates) do
            updateFunction(self, dt)
        end
    end
    
    entity.move = function(self, newI, newJ)
        self.i, self.j = newI, newJ
    end
    
    entity.onNewTurn = function () end
    
    entity.draw = function (self)
        love.graphics.setColor(self.color or {.8, 0, .8})
        love.graphics.translate(self.x, self.y)
        love.graphics.circle("fill", 0, 0, 16)
    end
    
    entity.snapToGrid = function (self)
        entity.x, entity.y = gridToScreen(entity.i, entity.j)
    end

    applyParams(entity, params)
    if entity.i and entity.j then
        entity.snapToGrid()
    end

    entity.loadAnimation = function (self, spriteSet)
        print(self.w, self.h)
        if self.spriteSet then
            self.animation = newAnimation(love.graphics.newImage(self.spriteSet.path or spriteSet.path or spriteSet),
             self.spriteSet.width or spriteSet.width or 16, self.spriteSet.height or spriteSet.height or 16, 1, 32, 32)
        end
        if self.animation then
            self.draw = function (self)
                love.graphics.translate(self.x+.5*zoomX*tileSize, self.y+zoomY*tileSize-.5*self.h)
                self.animation:draw()
            end
            table.insert(self.updates,
                function (self, dt)
                    self.animation:update(dt)
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
            )
        end
    end
    table.insert(entities, entity)
    return entity
end