-- vim: set noexpandtab:

text = "START" 

function load() 
	-- name of the game
	love.graphics.setCaption("escape from generic death star")

	-- first line for ground
	punkte = {}
	punkte[1] = {
		x1 = 0,
		y1 = 0,
		x2 = 30,
		y2 = 30,
	}

	-- generate up to 500 lines for ground
	for p = 2,500 do
		punkte[p] = {
			x1 = punkte[p-1].x2,
			y1 = punkte[p-1].y2,
			x2 = punkte[p-1].x2 + math.random(50,200),
			y2 = math.random(-100,100)
		}
	end
	
	-- first line for top
	tpunkte = {}
	tpunkte[1] = {
		x1 = 0,
		y1 = 0,
		x2 = 30,
		y2 = 30,
	}

	-- generate up to 500 lines for top
	for p = 2,500 do
		tpunkte[p] = {
			x1 = tpunkte[p-1].x2,
			y1 = tpunkte[p-1].y2,
			x2 = tpunkte[p-1].x2 + math.random(50,200),
			y2 = math.random(-100,100)
		}
	end

	-- create a world with size 
	world = love.physics.newWorld(200000, 2000) 
	-- gravity at the beginning is zero
	world:setGravity(0, 0) 
 
	-- create the ground and top body at (0, *) with mass 0 
	ground = love.physics.newBody(world, 0, 450, 0) 
	top = love.physics.newBody(world, 0, 100, 0) 

	-- create the ground and top shape, connection between the start and endpoint of each line and some thickness because polygons are needed 
	for i = 1,500 do
		punkte[i].shape = love.physics.newPolygonShape(ground,
			punkte[i].x1, 150,
			punkte[i].x1, punkte[i].y1,
			punkte[i].x2, punkte[i].y2,
			punkte[i].x2, 150
		)
	 end 
	 
	for i = 1,500 do
		tpunkte[i].shape = love.physics.newPolygonShape(top,
			tpunkte[i].x1, -150,
			tpunkte[i].x1, tpunkte[i].y1,
			tpunkte[i].x2, tpunkte[i].y2,
			tpunkte[i].x2, -150
		)
	 end 

	-- create ship body at 400,200
	ship = love.physics.newBody(world, 400, 200) 
	
	-- attach ship shape to its body
	ship_shape = love.physics.newPolygonShape(ship, 0, 0, 50, 15, 0, 30)
	
	-- mass of spaceship, center may be at 20,15 :) weight is 2000, intertia 1, no idea y, but it works 
	ship:setMass(20, 15, 2000, 1) 
	
	-- set the collision callback 
	world:setCallback(collision) 
 
	up = 0
	elapsed = 0
	start = 0
	menu = 1
	
	-- define used fonts
	font12 = love.graphics.newFont(love.default_font, 12) 
	font20 = love.graphics.newFont(love.default_font, 20) 
	
end
 
function update(dt) 
	-- update the world 
	world:update(dt)  
	 
	 if menu == 0 then
			if elapsed < 5 then
				text = string.format("Start in %d", 6 - elapsed)
				elapsed = elapsed + dt
			else
				start = 1
				world:setGravity(0, 100) 
				ship:applyImpulse(0, 1)
				elapsed = 7
				text = ""
			end
	 end
	 
	 if start == 1 then
			ground:setX(ground:getX() - dt * 100)
			top:setX(top:getX() - dt * 100)
			if up == 1 then 
				 ship:applyImpulse(0, -500000 * dt)
			end
	 end
end 
 
function draw() 
	love.graphics.setFont(font12)
	love.graphics.setColor(180, 180, 180)
	 
	-- draw the polygons with lines
	for i = 1,500 do		
		love.graphics.polygon(love.draw_fill, punkte[i].shape:getPoints()) 
	end
	
	for i = 1,500 do		
		love.graphics.polygon(love.draw_fill, tpunkte[i].shape:getPoints()) 
	end
 
	-- draw spaceship only if the game is not lost
	if text ~= "GAME OVER" then
		love.graphics.polygon(love.draw_line, ship_shape:getPoints()) 
	end
	 
	love.graphics.setColor(255, 255, 255)

	-- draw text
	love.graphics.draw(text, 390, 300) 
	 
	-- draw menu
	-- startmenu
	if menu == 1 then
		love.graphics.setColor(15, 193, 153)
		love.graphics.rectangle(0, 100, 100, 600, 400)
		menuitem(0, "START GAME")
		menuitem(1, "INSTRUCTION")
		menuitem(2, "CREDITS")
		menuitem(3, "EXIT")
	end
	-- instruction menu
	if menu == 2 then
		love.graphics.setColor(15, 193, 153)
		love.graphics.rectangle(0, 100, 100, 600, 400)
		love.graphics.setColor(255, 255, 255)
		love.graphics.setFont(font20)
		love.graphics.draw("Das übliche...\nAlso BÄM BÄM BÄM", 340, 180)
		menuitem(3, "ZURÜCK")
	end
	-- credits menu
	if menu == 3 then
		love.graphics.setColor(15, 193, 153)
		love.graphics.rectangle(0, 100, 100, 600, 400)
		love.graphics.setColor(255, 255, 255)
		love.graphics.setFont(font20)
		love.graphics.draw("Real Entertainment Unified Developing Enterprise", 150, 180)
		menuitem(3, "ZURÜCK")
	end	
	-- exit programm
	if menu == 4 then
		os.exit()
	end	 
end 

function menuitem(position, caption)
	love.graphics.setColor(6, 77, 61)
	love.graphics.rectangle(0, 150, 150 + position * 75, 500, 50)
	love.graphics.setColor(255, 255, 255)
	love.graphics.setFont(font20)
	love.graphics.draw(caption, 340, 180 + position * 75)	 
end

function menubutton(position, from, to, x, y)
	 if menu == from then
			if x > 150 and y > 150 + position * 75 and x < 650 and y < 200 + position * 75 then
				menu = to
			end
	 end
end
			
function mousepressed(x, y, button)
	up = 1
	-- on which position is the button, from and to which menu, and the mouse position for the function
	menubutton(0, 1, 0, x, y)
	menubutton(1, 1, 2, x, y)
	menubutton(2, 1, 3, x, y)
	menubutton(3, 1, 4, x, y)
	menubutton(3, 2, 1, x, y)
	menubutton(3, 3, 1, x, y)
end

function mousereleased(x, y, button)
	up = 0
end
 
-- this is called every time a collision occurs 
function collision(a, b, c) 
	text = "GAME OVER"
	menu = 1
	start = 0
	world:setGravity(0, 0) 
end
