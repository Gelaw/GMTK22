require "base"
require "ui"

function projectSetup()
  love.graphics.setBackgroundColor(.3, .3, .3)
end


function love.mousepressed(x, y, button, isTouch)
  UIMousePress(x, y , button)
end

function love.mousereleased(x, y, button, isTouch)
  UIMouseRelease(x, y, button)
end

function love.keypressed(key, scancode, isrepeat)
  --https://www.youtube.com/watch?v=79DijItQXMM
  if key == "escape" then
    love.event.quit()
  end
end
