-- vim: set noexpandtab:

text = "START" 
survived = 0.0

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
has_canon = false

effect_state = {
	score_multiplier = 1,
	inverted_controls = false,
	ship_size = 1,
	speed = 100,
	running_effects = {}
}

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
	math.randomseed(os.time())

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
	ok, err = pcall(update_, dt)
	if not ok then
		print(err)
		os.exit(1)
	end
end
function update(dt) 
	-- See if there are stream_items that are already scrolled away
	-- (check every 5 seconds)
	gc_elapsed = gc_elapsed + dt
	if gc_elapsed >= 5.0 then
		gc_elapsed = 0.0
		local to_delete = {}
		for i, v in ipairs(stream_items) do
			if v == nil or (v.obsolete ~= nil and v:obsolete()) then
				if v.kind == 'canon' then
					has_canon = false
				end
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

	-------[[ handle effects ]]-------

	-- Decrease effect time or turn effect off when its over
	for i, effect in ipairs(effect_state.running_effects) do
		if effect.timeout > 0 then
			effect.timeout = effect.timeout - dt
		else
			effect.off()
			-- We're currently iterating, set the to-delete effect to nil
			effect_state.running_effects[i] = nil
		end
	end
	-- clean up nil effects
	for i=#effect_state.running_effects,1,-1 do
		if effect_state.running_effects[i] == nil then
			table.remove(effect_state.running_effects, i)
		end
	end

	---------[[ handle menu stuff ]]-------

	if menu == 0 then
			if elapsed < 1 then
				text = string.format("Start in %d", 2 - elapsed)
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

	---------[[ score and ground movement ]]-------

	if start == 1 then
		 	survived = survived + dt
			score = score + 100 * dt * effect_state.score_multiplier
			ground:setX(ground:getX() - dt * effect_state.speed)
			top:setX(top:getX() - dt * effect_state.speed)
			if up then 
				ship:applyImpulse(0, -500000 * dt)
			end

			-- get new stream items
			while stream:max_x() < (-top:getX() + 1000) do
				local item = stream:pop()
				table.insert(stream_items, item)
				if item.kind == 'canon' then
					has_canon = true
				end
			end
	end
end 
 
function draw()
	ok, err = pcall(draw_)
	if not ok then
		print(err)
		os.exit(1)
	end
end

function draw_() 
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
		love.graphics.setColor(70, 90, 80)
		love.graphics.polygon(love.draw_fill, ship_shape:getPoints()) 
		love.graphics.setColor(120, 140, 130)
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
	if start == 1 then
		local y = 30
		local scroll_in_time = 0.5
		local scroll_out_time = 0.5
		love.graphics.setFont(font20)
		for i, effect in ipairs(effect_state.running_effects) do
			love.graphics.setColor(200, 80, 60)
			local x = 30
			local f = 1.0
			if effect.timeout > (effect.timeout_original - scroll_in_time) then
				-- scroll in
				f = (effect.timeout_original - effect.timeout) / scroll_in_time
			elseif effect.timeout < scroll_out_time then
				-- scroll out
				f = effect.timeout / scroll_out_time
			end
			x = (30 - 400) + 400 * f
			love.graphics.setColor(200 * f, 80 * f, 60 * f)
			local m = ''
			love.graphics.draw(string.format("%04.2f %s%s",effect.timeout, effect.message, m), x, y)
			y = y + 30
		end
	end

	love.graphics.setFont(font12)
	-- Intentionally draw these always so user can see its latest score in menu
	love.graphics.setColor(255,255,255)
	local text_survived = string.format("%06.0f seconds of survival", survived)
	love.graphics.draw(text_survived, 500, 30)

	local text_score = string.format("SCORE: %010d x%d", score, effect_state.score_multiplier)
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
			
function mousepressed(x, y, button)
	up = not effect_state.inverted_controls
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
		effect_state = {
			score_multiplier = 1,
			inverted_controls = false,
			ship_size = 1,
			speed = 100,
			running_effects = {}
		}
		-- and more...
	end
end

function mousereleased(x, y, button)
	up = effect_state.inverted_controls
end

function collision(a, b, c)
	ok, err = pcall(collision_, a, b, c)
	if not ok then
		print(err)
		os.exit(1)
	end
end

-- this is called every time a collision occurs 
function collision_(a, b, c) 
	local c_border = false
	local c_ship = false
	local c_item = false
	local item = nil
	for i, obj in ipairs({a, b}) do
		if obj ~= nil and obj.collision_type ~= nil then
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

		local e = {}
		e.timeout_original = item.effect_timeout
		e.timeout = item.effect_timeout
		e.message = item.effect_message
		e.off = item.effect_off
		table.insert(effect_state.running_effects, e)
		debug("turning on:", e.message)
		item:effect_on()

		-- stabilize ship
		ship:setSpin(0)
		ship:setVelocity(0, 0)
		ship:setAngle(0)

		-- destroy item
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

	elseif c_item and c_border then
		item.shape:setMaskBits(0)
	
	end

end
