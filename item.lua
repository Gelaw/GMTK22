equipmentTypes = {"mainhand", "offhand", "armor"}
itemTypes = {"sword", "armor"}

function newItem(params)
    local item = {
        name = "default item name",
        itemType = "weapon",
        equipmentType = "mainhand",
        stats = {},
        sprite = dungeonSprites,
        quad = todoQuad,
        color = {1, 1, 1},
        drawSprite = function (self)
            love.graphics.setColor(self.color)
            love.graphics.draw(self.sprite, self.quad)
        end,
        drawTooltip = function (self, x, y, w, h)
            local text = ""
            text = text .. self.name .. "\t" .. self.itemType .. "\n"
            text = text .. self.equipmentType .. "\n"
            text = text .. "Stats:" .. "\n"
            for s, stat in pairs(self.stats) do
                text = text .. "\t" .. stat .." ".. s.."\n"
            end
            love.graphics.printf(text, x, y, w)
        end
    }
    return applyParams(item, params)
end

