-- vim: set noexpandtab:

config = {
	resolution = {x=800, y=600},
	button_up = 1,
}

love.filesystem.require('utils.lua')
love.filesystem.require('background.lua')
love.filesystem.require('border.lua')
love.filesystem.require('camera.lua')
love.filesystem.require('item_generator.lua')

game_state = nil
world = nil
ship = nil
controls = nil
bg0 = nil
bg1 = nil
main_border = nil
items = nil
fonts = nil
-- for collision
category = { 
	ship = 2,
	border = 3,
	item = 4
}

function switch_phase(new_phase)
	game_state.phase = new_phase
	game_state.phase_duration = 0
end

function update_ship_shape()
	if ship.shape ~= nil then
		ship.shape:setData(nil)
		ship.shape:destroy()
	end
	ship.shape = love.physics.newPolygonShape(ship.body,
		0, -15 * game_state.ship_size, 50*game_state.ship_size, 0, 0, 15*game_state.ship_size
	)
	ship.shape:setData(ship)
	ship.shape:setCategory(category.ship)
end

function start_game()

	-- Set up game state
	game_state = {
		phase = 'running', -- countdown / running / gameover
		score_multiplier = 1,
		phase_duration = 0,
		inverted_controls = false,
		ship_size = 1,
		speed = 200,
		invincible = false,
		lives = 3,
		running_effects = {}
	}

	controls = {
		up = false
	}

	-- Set up world
	world = love.physics.newWorld(
		-config.resolution.x * 1, -config.resolution.y * 2000,
		config.resolution.x * 20000, config.resolution.y * 2000, 0, 100, true)
	world:setCallback(collision) 

	-- Set up ship
	local ship_body = love.physics.newBody(world, 0, 0)
	local ship_shape = love.physics.newPolygonShape(ship_body, 0, -15, 50, 0, 0, 15)
	ship_body:setMassFromShapes()
	ship = {
		type = 'ship',
		body = ship_body,
		shape = ship_shape
	}
	ship_shape:setData(ship)
	ship_shape:setCategory(category.ship)

	world_camera = camera.new()
	world_camera:setScreenOrigin(0.5, 0.5)

	-- Cool for debugging background & borders
	--world_camera:scaleBy(.5, .5)

	gui_camera = camera.new()
	gui_camera:setScreenOrigin(0, 0)

	-----[[ Initialize various "streams" ]]------

	bg0 = background.new(game_state.speed - 50)
	bg0:init()

	bg1 = parallax.new(game_state.speed - 100)
	bg1:init()

	main_border = border.new(
		0.6, -- min top/bottom distance
		0.1, -- piece width
		0.1 -- max change in height
	)
	main_border.max_distance = 1.5 * config.resolution.y
	main_border.cannon_interval = 1.0
	main_border.cannon_power = 300
	main_border:init()

	items = item_generator.new(0.005)
	items:init()

	apply_effect(invincible)

end

function load()
	math.randomseed(os.time())
	love.graphics.setCaption("Escape from generic death star")

	fonts = {
		small = love.graphics.newFont(love.default_font, 12),
		normal = love.graphics.newFont(love.default_font, 20),
		giant = love.graphics.newFont(love.default_font, 96)
	}

	start_game()
end

function update_(dt)
	ship.body:setX(ship.body:getX() + dt * game_state.speed)
	world_camera:setOrigin(ship.body:getX(), ship.body:getY())
	local phase = game_state.phase

	game_state.phase_duration = game_state.phase_duration + dt

	if phase == 'running' or phase == 'gameover' then
		world:update(dt)
		main_border:update(dt)
	end

	if phase == 'running' then
		bg0:update(dt)
		bg1:update(dt)
		items:update(dt)
		if controls.up ~= game_state.inverted_controls then
			ship.body:applyImpulse(0, -300000 * dt)
		end

		-- Update effects
		local to_delete = {}
		for i, effect in ipairs(game_state.running_effects) do
			if effect ~= nil then
				effect.timeout = effect.timeout - dt
				if effect.timeout <= 0 then
					effect.off()
					table.insert(to_delete, 1, i)
				end
			end
		end
		for i, idx in ipairs(to_delete) do
			table.remove(game_state.running_effects, idx)
		end
	end
end

function draw_()
	-- Set some defaults & shorthands
	setCamera(world_camera)
	love.graphics.setColorMode(love.color_modulate)
	love.graphics.setLineWidth(3)
	local x0, y0, x1, y1 = get_visible_area()
	local phase = game_state.phase

	-- The very background
	love.graphics.setColor(90, 90, 90)
	love.graphics.rectangle(love.draw_fill, x0, y0, x1-x0, y1-y0)

	bg0:draw()
	bg1:draw()

	main_border:draw()
	items:draw()

	if phase == 'running' then

		-- Upwards engine blast
		if controls.up ~= game_state.inverted_controls then
			love.graphics.setColor(220, 220, 80, 40)
			love.graphics.circle(love.draw_fill,
				ship.body:getX() + game_state.ship_size * 20,
				ship.body:getY() + game_state.ship_size * 12,
				game_state.ship_size * 20
			)
			love.graphics.circle(love.draw_fill,
				ship.body:getX() + game_state.ship_size * 20,
				ship.body:getY() + game_state.ship_size * 12,
				game_state.ship_size * 15
			)
			love.graphics.circle(love.draw_fill,
				ship.body:getX() + game_state.ship_size * 20,
				ship.body:getY() + game_state.ship_size * 12,
				game_state.ship_size * 10
			)
		end

		-- Ship
		local tr
		if game_state.invincible then tr = 100
		else tr = 255 end
		love.graphics.setColor(80, 90, 80, tr)
		love.graphics.polygon(love.draw_fill, ship.shape:getPoints()) 
		love.graphics.setColor(130, 140, 130)
		love.graphics.setLineWidth(3)
		love.graphics.polygon(love.draw_line, ship.shape:getPoints()) 


		---[[ GUI STUFF ]]---

		setCamera(gui_camera)

		-- Life counter
		function draw_mini_ship(x, y)
			local ps = {ship.shape:getPoints()}
			for i = 1, #ps, 2 do
				ps[i] = (ps[i] - ship.body:getX()) / (game_state.ship_size * 2) + x
				ps[i+1] = (ps[i+1] - ship.body:getY()) / (game_state.ship_size * 2) + y
			end
			love.graphics.setColor(80, 90, 80, tr)
			love.graphics.polygon(love.draw_fill, unpack(ps))
			love.graphics.setLineWidth(1)
			love.graphics.setColor(130, 140, 130)
			love.graphics.polygon(love.draw_line, unpack(ps))
		end

		for l = 1,game_state.lives do
			draw_mini_ship(790 - l * 30, 30)
		end

		-- Running effects
		local y = 30
		local scroll_in_time = 0.5
		local scroll_out_time = 0.5
		love.graphics.setFont(fonts.normal)
		for i, effect in ipairs(game_state.running_effects) do
			if effect ~= nil then
				local color = {200, 80, 60}
				if effect.color ~= nil then
					color = effect.color
				end
				love.graphics.setColorMode(love.color_modulate)
				love.graphics.setColor(unpack(color))
				local x = 30
				local f = 1.0 -- fade in/out [0...1]
				local rt = effect.timeout / effect.timeout_original
				if effect.timeout > (effect.timeout_original - scroll_in_time) then
					-- scroll in
					f = (effect.timeout_original - effect.timeout) / scroll_in_time
				elseif effect.timeout < scroll_out_time then
					-- scroll out
					f = effect.timeout / scroll_out_time
				end
				x = (30 - 400) + 400 * f
				love.graphics.setColor(color[1], color[2], color[3], 50 + 205 * rt)
				local m = ''
				if effect.show_timeout == nil or effect.show_timeout == true then
					love.graphics.draw(string.format("%04.2f %s%s",effect.timeout, effect.message, m), x, y)
				else
					love.graphics.draw(string.format("       %s%s",effect.message, m), x, y)
				end
				y = y + 30
			end
		end

		setCamera(world_camera)

	end

	if phase == 'gameover' then
		local s = 'GAME OVER'
		local font = fonts.giant
		local w = font:getWidth(s)
		local h = font:getHeight()
		local t = 1
		local x0, y0, x1, y1 = get_visible_area()
		local dx = x1-x0
		local dy = y1-y0

		love.graphics.setColor(255, 0, 0)
		love.graphics.setFont(font)
		if game_state.phase_duration < t then
			local alpha = game_state.phase_duration * 360
			local scale = game_state.phase_duration / t
			local x = x0 + dx/2 - math.cos(math.rad(alpha)) * w/2 * scale^2
			local y = y0 + dy/2 - math.sin(math.rad(alpha)) * w/2 * scale^2
			love.graphics.draw(s, x,y, alpha, game_state.phase_duration / t)
		else
			love.graphics.draw(s, x0 + dx/2 - w/2, y0 + dy/2)
		end
	end
end

function mousepressed_(x, y, button)
	if button == config.button_up then controls.up = true end
end

function mousereleased_(x, y, button)
	if button == config.button_up then controls.up = false end
end

function apply_effect(effect)
	effect.on()
	-- Copy effect (so it can be there multiple times with different timeout
	-- values etc...
	local eff = {}
	for k, v in pairs(effect) do
		eff[k] = v
	end
	eff.timeout_original = eff.timeout
	table.insert(game_state.running_effects, eff)
end

function collision_(a, b, c)
	local counts = { ship = 0, border = 0, item = 0 }
	local item = nil
	local border = nil

	for i, x in ipairs({a, b}) do
		if x ~= nil then
			counts[x.type] = counts[x.type] + 1
			if x.type == 'item' then
				item = x
			elseif x.type == 'border' then
				border = x
			end
		end
	end

	if game_state.phase ~= 'running' then
		return
	end

	if counts.ship == 1 and counts.item == 1 then
		item.is_obsolete = true
		item.shape:setData(nil)
		item.shape:destroy()
		item.body:destroy()
		apply_effect(item.effect)

		-- stabilize ship
		ship.body:setSpin(0)
		ship.body:setVelocity(0, 0)
		ship.body:setAngle(0)

	elseif counts.ship == 1  then
		if not game_state.invincible then
			game_state.lives = game_state.lives - 1
		end
		if game_state.lives < 1 then
			-- Game over!
			world_camera:setScaleFactor(1, 1)
			gui_camera:setScaleFactor(1, 1)
			switch_phase('gameover')
		else
			-- set back ship to safe position & stabilize
			ship.body:setPosition(
				border.top.x,
				(border.top.y + border.bottom.y) / 2
			)
			ship.body:setSpin(0)
			ship.body:setVelocity(0, 0)
			ship.body:setAngle(0)
			if not game_state.invincible then
				for i, effect in ipairs(game_state.running_effects) do
					effect.off()
				end
				game_state.running_effects = {}
				apply_effect(invincible)
			end
		end
	end
end



update = makesafe(update_)
draw = makesafe(draw_)
mousepressed = makesafe(mousepressed_)
mousereleased = makesafe(mousereleased_)
collision = makesafe(collision_)

camera.lateInit()

