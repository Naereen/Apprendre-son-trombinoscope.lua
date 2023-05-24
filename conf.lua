-- https://love2d.org/wiki/Config_Files

function love.conf(t)
    t.window.width = 1510
    t.window.minwidth = 1024
    t.window.height = 850
    t.window.minheight = 768
    t.modules.joystick = false
    t.modules.physics = false
end
