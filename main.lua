-- vim: set noexpandtab:

text = "START" 
survived = 0.0
speed = 100.0
effect_off = nil
effect_timeout = 0.0
effect_message = nil

-- the level stream
stream = nil
-- stream "cache"
stream_items = {}
--debug = function() end
debug = function(...)
	print(...)
	io.flush()
end
font12 = nil
font20 = nil
score = 0
score_multiplier = 1

function init_ship()
	-- create ship body at 400,200
	ship = love.physics.newBody(world, 400, 200) 
	
	-- attach ship shape to its body
	ship_shape = love.physics.newPolygonShape(ship, 0, 0, 50, 15, 0, 30)
	ship_shape:setData({
		collision_type = 'ship'
	})
	
	-- mass of spaceship, center may be at 20,15 :) weight is 2000, intertia 1, no idea y, but it works 
	ship:setMass(20, 15, 2000, 1) 
end
	

function load() 
	-- name of the game
	love.graphics.setCaption("escape from generic death star")

	-- create a world with size 
	world = love.physics.newWorld(200000, 2000) 
	-- gravity at the beginning is zero
	world:setGravity(0, 0) 
 
	-- create the ground and top body at (0, *) with mass 0 
	ground = love.physics.newBody(world, 0, 450, 0) 
	top = love.physics.newBody(world, 0, 100, 0) 

	stream = require('random_world_stream.lua').create()

	init_ship()

	-- set the collision callback 
	world:setCallback(collision) 
 
	up = false
	elapsed = 0
	start = 0
	menu = 1

	-- define used fonts
	font12 = love.graphics.newFont(love.default_font, 12) 
	font20 = love.graphics.newFont(love.default_font, 20) 
	
end

gc_elapsed = 0.0
function update(dt) 
	-- See if there are stream_items that are already scrolled away
	-- (check every 5 seconds)
	gc_elapsed = gc_elapsed + dt
	if gc_elapsed >= 5.0 then
		gc_elapsed = 0.0
		local to_delete = {}
		for i, v in ipairs(stream_items) do
			if v == nil or (v.obsolete ~= nil and v:obsolete()) then
				table.insert(to_delete, i)
			end
		end
		-- This is actually a 'reverse' operation
		table.sort(to_delete, function(a,b) return a>b end)
		for j, idx in ipairs(to_delete) do
			stream_items[idx].shape:setData(nil)	
			stream_items[idx].shape:destroy()	
			table.remove(stream_items, idx)
		end
	end

	-- Call update callbacks for items that have one
	for i, item in ipairs(stream_items) do
		if item ~= nil and item.update ~= nil then
			item:update(dt)
		end
	end

	-- update the world 
	world:update(dt)  

	-- Decrease effect time or turn effect off when its over
	if effect_off ~= nil then
		--debug("effect_off=", effect_off, "effect_timeout=", effect_timeout)
		if effect_timeout > 0 then
			effect_timeout = effect_timeout - dt
		else
			effect_off()
			effect_off = nil
		end
	end

	if menu == 0 then
			if elapsed < 5 then
				text = string.format("Start in %d", 6 - elapsed)
				elapsed = elapsed + dt
			elseif start ~= 1 then
				start = 1
				world:setGravity(0, 100) 
				survived = 0.0
				score = 0
				ship:applyImpulse(0, 1)
				elapsed = 7
				text = ""
			end
	end

	 
	 if start == 1 then
		 	survived = survived + dt
			score = score + 100 * dt * score_multiplier
			ground:setX(ground:getX() - dt * speed)
			top:setX(top:getX() - dt * speed)
			if up then 
				ship:applyImpulse(0, -500000 * dt)
			end

			if stream:max_x() < (-top:getX() + 1000) then
				table.insert(stream_items, stream:pop())
				--debug("stream items:", #stream_items)
			end
	end
end 
 
function draw() 
	love.graphics.setColor(255, 255, 255)
	love.graphics.setFont(font12)

	-- draw the polygons with lines
	for i, v in ipairs(stream_items) do
		if v ~= nil and v.draw ~= nil then
			v:draw()
		end
	end
 
	-- draw spaceship only if the game is not lost
	if text ~= "GAME OVER" then
		love.graphics.setColor(255, 255, 255)
		love.graphics.polygon(love.draw_line, ship_shape:getPoints()) 
	end
	
	-- reset button for testing
	
	love.graphics.setColor(255, 0, 0)
	love.graphics.rectangle(0, 750, 550, 40, 20)
	love.graphics.setColor(0, 0, 255)
	love.graphics.draw("RESET", 752, 565)

	-- draw text
	love.graphics.setColor(255, 255, 255)
	love.graphics.setFont(font12)
	love.graphics.draw(text, 390, 300) 
	if start == 1 and effect_timeout > 0 then
		love.graphics.setFont(font20)
		love.graphics.setColor(255, 40, 30)
		local x = 30
		if effect_timeout < 1 then
			x = (30 - 400) + 400 * effect_timeout
			love.graphics.setColor(
				255 * effect_timeout,
				40 * effect_timeout,
				30 * effect_timeout)
		end
		love.graphics.draw(string.format("%04.2f %s",effect_timeout, effect_message), x, 30)
	end

	love.graphics.setFont(font12)
	-- Intentionally draw these always so user can see its latest score in menu
	love.graphics.setColor(128, 128, 128)
	local text_survived = string.format("%06.0f seconds of survival", survived)
	love.graphics.draw(text_survived, 500, 30)

	local text_score = string.format("SCORE: %010d", score)
	love.graphics.draw(text_score, 500, 45)
	
	love.graphics.setColor(255, 255, 255)
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
			
invert_controls = false
function mousepressed(x, y, button)
	up = not invert_controls
	-- on which position is the button, from and to which menu, and the mouse position for the function
	menubutton(0, 1, 0, x, y)
	menubutton(1, 1, 2, x, y)
	menubutton(2, 1, 3, x, y)
	menubutton(3, 1, 4, x, y)
	menubutton(3, 2, 1, x, y)
	menubutton(3, 3, 1, x, y)
	-- resetbutton
	if x > 750 and y > 550 and x < 790 and y < 570 then
		ship:setY(200)
		ship:setX(400)
		ship:setAngle(0)
		ship:setSpin(0)
		ship:setVelocity(0,0)
		start = 0
		elapsed = 0
		world:setGravity(0, 0)
		stream_items = {}
		stream.top.x = 0
		stream.top.y = 0
		stream.bottom.x = 0
		stream.bottom.y = 0
		speed = 100.0
		effect_off = nil
		effect_timeout = 0.0
		effect_message = nil
		invert_controls = false
		-- and more...
	end
end

function mousereleased(x, y, button)
	up = invert_controls
end
 
-- this is called every time a collision occurs 
function collision(a, b, c) 
	local c_border = false
	local c_ship = false
	local c_item = false
	local item = nil
	for i, obj in ipairs({a, b}) do
		if obj ~= nil and obj.collision_type ~= nil then
		--debug("---")
		--table.foreach(stream_items, print)
			if obj.collision_type == 'border' then c_border = true end
			if obj.collision_type == 'ship' then c_ship = true end
			if obj.collision_type == 'item' then
				c_item = true
				item = obj
			end
		end
	end

	if c_ship and c_border then -- ship+border = death
		world:setGravity(0, 0) 
		text = "GAME OVER"
		menu = 1
		start = 0

	elseif c_ship and c_item then -- ship+item = ask item what to do

		--[[ WELCOME TO SEGFAULT AREA ]]--

		if effect_off ~= nil then
			effect_off()
			effect_off = nil
		end

		debug("setting up effect:", item.effect_message)
		effect_timeout = item.effect_timeout
		effect_message = item.effect_message
		effect_off = item.effect_off
		item:effect_on()

		-- stabilize ship
		ship:setSpin(0)
		ship:setVelocity(0, 0)
		ship:setAngle(0)
	end

	-- If item was involved in a collision, destroy it
	if c_item then
		-- make shape non-colliding until garbage collecter munches it
		item.shape:setMaskBits(0)
		item.shape:setData(nil)
		for j, it in ipairs(stream_items) do
			if it ~= nil and it == item then
				table.remove(stream_items, j)
				break
			end
		end
		-- om nom nom nom
		debug("body count before gc:", world:getBodyCount())
		collectgarbage()
		debug("body count after gc:", world:getBodyCount())
	end

end
