-- Un jeu Löve2D pour apprendre un trombinoscope
-- Écrit en mai 2023 par Elliot C. et Lilian Besson
-- MIT Licensed

local utf8 = require("utf8")
local love = require("love")

-- Chargement des ressources pour le jeu.
function love.load()
    font = love.graphics.newFont("DejaVuSans.ttf", 26)
    love.graphics.setFont(font)

    love.window.setTitle("Apprendre mon Trombinoscope ~ par Elliott et Lilian")

    enabled = love.keyboard.hasTextInput()
    if not enabled then
        love.graphics.print("Text input is not available! Change your device.", 0, 0)
    end

    files = love.filesystem.getDirectoryItems("img/")
    images = {}
    names = {}
    for _, v in ipairs(files) do
        if isJpg(v) then
            table.insert(images, love.graphics.newImage("img/" .. v))
            table.insert(names, v)
            print("Ouverture de l'image", v, "...")
        end
    end

    nombre_images = #images
    names = sepNoms(names)

    for i, v in ipairs(names) do
        print("#", i, " NOM : " .. v[1] .. ", Prénom : " .. v[2])
    end

    index = 1

    height = love.graphics:getHeight() - 200
    width  = height * 0.86  -- aspect ratio TODO: generalize this?

    x = love.graphics:getWidth() / 2 - width / 2
    y = 0

    buttonImage = love.graphics.newImage("img/banana.png")  -- TODO: use a real arrow button?
    buttonNext  = {x = x + width + 50, y = y + height / 2, width = 50, height = 70}

    -- enable key repeat so backspace can be held down to trigger love.keypressed multiple times.
    love.keyboard.setKeyRepeat(true)

    textbox1 = {
        x = x, y = y + height + 50,
        width = width, height = 100,
        text = "",
        active = false,
        colors = {
            background = { 255, 255, 255, 255 }, -- rgb(255,255,255,255)
            text       = { 0, 0, 0, 255 }        -- rgb(0,0,0,255)
        }
    }
end

-- Update while drawing
function love.update(dt)
    local str1 = string.lower(textbox1.text)
    local str2 = names[index][1] .. " " .. names[index][2]
    str2 = string.lower(str2)
    distance = string.levenshtein(str1, str2)
end

-- Draw on the screen
function love.draw()
    love.graphics.setColor(1, 1, 1)
    if #images > 0 and index <= #images then
        local im = images[index]
        love.graphics.draw(im, x, y, 0,
            width / im:getWidth(), height / im:getHeight()
        )
    else
        index = 1
    end

    love.graphics.draw(buttonImage, buttonNext.x, buttonNext.y, 0,
                    buttonNext.width / buttonImage:getWidth(), buttonNext.height / buttonImage:getHeight())

    love.graphics.setColor(textbox1.colors.background)
    love.graphics.rectangle('fill', textbox1.x, textbox1.y, textbox1.width, textbox1.height)
    love.graphics.setColor(textbox1.colors.text)
    love.graphics.printf(textbox1.text, textbox1.x, textbox1.y, textbox1.width, 'left')

    love.graphics.setColor(1, 1, 1)

    love.graphics.setFont(font)
    love.graphics.print("NOM Prénom :", font, 0, textbox1.y)
    love.graphics.print(names[index][1], font, 0, textbox1.y + 50)
    love.graphics.print(names[index][2], font, 0, textbox1.y + 100)
    love.graphics.print("Dist. = " .. distance, font, love.graphics:getWidth() - 200, textbox1.y)
end

function love.keypressed(key)
    if key == "right" then
        switchImage()
    end
    if key == "backspace" then
        -- get the byte offset to the last UTF-8 character in the string.
        if textbox1.active then
            local byteoffset = utf8.offset(textbox1.text, -1)

            if byteoffset then
                -- remove the last UTF-8 character.
                -- string.sub operates on bytes rather than UTF-8 characters, so we couldn't do string.sub(text, 1, -2).
                textbox1.text = string.sub(textbox1.text, 1, byteoffset - 1)
            end
            -- print("textbox1.text =", textbox1.text)
        end
    elseif key == "enter" then
        if textbox1.active then
            textbox1.active = false
        end
    elseif key == "escape" then
        love.event.quit()
    end
end

function love.mousepressed(x, y)
    if testPoint(buttonNext, x, y) then
        switchImage()
    end

    if testPoint(textbox1, x, y) then
        print("Textbox is now active!")
        textbox1.active = true
    elseif textbox1.active then
        print("Textbox is now inactive...")
        textbox1.active = false
    end
end

function love.textinput(text)
    if textbox1.active then
        textbox1.text = textbox1.text .. text
        -- print(text)
    end
end

function switchImage()
    if distance == 0 then
        print("Réussite pour le nom", textbox1.text, "photo d'indice #", index)
        textbox1.text = ""
        index = index + 1
    else
        print("Impossible de passer à l'image suivante sans taper le nom complet.")
    end
end

function isJpg(s)
    return string.sub(s, -4) == ".jpg"
end

function testPoint(rect, x, y)
    return ((rect.x < x and x < (rect.x + rect.width)) and (rect.y < y and y < (rect.y + rect.height)))
end

function sepNoms(names)
    local namesSep = {}
    for i,s in ipairs(names) do
        s = string.sub(s, 0, -5)
        namesSep[i] = string.split(s, "_")
    end
    return namesSep
end

function string.split(str, sep)
    if sep == nil then
        sep = "%s"
    end
    local t={}
    for str in string.gmatch(str, "([^"..sep.."]+)") do
        table.insert(t, str)
    end
    return t
end

function string.levenshtein(str1, str2)
    local len1 = string.len(str1)
	local len2 = string.len(str2)
	local matrix = {}
	local cost = 0

        -- quick cut-offs to save time
	if (len1 == 0) then
		return len2
	elseif (len2 == 0) then
		return len1
	elseif (str1 == str2) then
		return 0
	end

        -- initialise the base matrix values
	for i = 0, len1, 1 do
		matrix[i] = {}
		matrix[i][0] = i
	end
	for j = 0, len2, 1 do
		matrix[0][j] = j
	end

        -- actual Levenshtein algorithm
	for i = 1, len1, 1 do
		for j = 1, len2, 1 do
			if (str1:byte(i) == str2:byte(j)) then
				cost = 0
			else
				cost = 1
			end

			matrix[i][j] = math.min(matrix[i-1][j] + 1, matrix[i][j-1] + 1, matrix[i-1][j-1] + cost)
		end
	end

        -- return the last value - this is the Levenshtein distance
	return matrix[len1][len2]
end
