-- vim: set noexpandtab:

item_generator={ class={} }
item_generator.class.__index = item_generator.class

function item_generator.new(cpp)
	local g = {
		chance_per_pixel = cpp,
		items = {},
		size = 10,
	}
	setmetatable(g, item_generator.class)
	return g
end

function item_generator.class:init()
end

function item_generator.class:update(dt)
	-- clean up obsolete items
	local to_delete = {}
	for i = 1,#self.items do
		if self.items[i] == nil or self.items[i]:obsolete() then
			-- insert at beginning of table, so highest index is first in list
			table.insert(to_delete, 1, i)
		else
			self.items[i].t = self.items[i].t + dt
			if self.items[i].t > 5 then self.items[i].t = 0 end
		end
	end
	for i, idx in ipairs(to_delete) do
		table.remove(self.items, idx)
	end

	local p = 1 - (1 - self.chance_per_pixel) ^ (game_state.speed * dt)
	local rnd = math.random()
	if rnd < p then
		self:generate_item()
	end
end

function item_generator.class:generate_item()
	local x0, y0, x1, y1 = get_visible_area()
	r = self:generate_item_at(
		ship.body:getX() + game_state.speed * (x1 - x0) / 250,
		y0
	)
	r.body:applyImpulse(math.random(-10000, -3000), 0)
	return r
end

function item_generator.class:generate_item_at(x, y)
	local body = love.physics.newBody(world, x, y, math.random(100, 1000))
	local shape = love.physics.newCircleShape(body, self.size)
	body:setSpin(360)
	shape:setCategory(category.item)
	shape:setMask(category.border)

	-- Select effect randomly
	local effect = item_effects[math.random(1, #item_effects)]

	item = {
		type = 'item', body = body, shape = shape, effect = effect,
		r = math.random(0, 255),
		g = math.random(0, 255),
		b = math.random(0, 255),
		t = 0,
		is_obsolete = false, size = self.size,
		obsolete = function(self)
			local x0, y0, x1, y1 = get_visible_area()
			return self.is_obsolete or
				self.body:getY() < y0 - (y1-y0) or
				self.body:getX() < x0 - self.size
		end
	}
	shape:setData(item)
	table.insert(self.items, item)
	return item
end

function item_generator.class:draw()
	for i, item in ipairs(self.items) do
		if item ~= nil and not item:obsolete() then
			local x, y = item.body:getPosition()
			local s = self.size
			local s2 = self.size / 5.0
			local a = item.body:getAngle()
			local r, g, b, t = item.r, item.g, item.b, item.t
			love.graphics.setColorMode(love.color_modulate)
			love.graphics.setColor(r + sin(t*360/5)*40, g + sin(t*360/5)*40, b + sin(t*360/5)*40, 128)
			love.graphics.polygon(love.draw_line,
				x + s *  sin(a),		 y + s *	cos(a),
				x + s2 * sin(a+60),  y + s2 * cos(a+60),
				x + s *  sin(a+120), y + s *	cos(a+120),
				x + s2 * sin(a+180), y + s2 * cos(a+180),
				x + s *  sin(a+240), y + s *	cos(a+240),
				x + s2 * sin(a+300), y + s2 * cos(a+300)
			)
		end
	end
end

item_effects = {
	--[[
	{
		message = 'SPEED BLAST',
		on = function() game_state.speed = game_state.speed * 2 end,
		off = function() game_state.speed = game_state.speed / 2 end,
		timeout = 10,
		color = { 70, 70, 200 }
	},
	{
		message = '!ENGINE DEPOLARIZED!',
		on = function() game_state.inverted_controls = not game_state.inverted_controls end,
		off = function() game_state.inverted_controls = not game_state.inverted_controls end,
		timeout = 10,
		color = { 200, 70, 70 }
	},
	{
		message = 'BIG BLAST',
		on = function()
			game_state.ship_size = game_state.ship_size + 1
			update_ship_shape()
		end,
		off = function()
			game_state.ship_size = game_state.ship_size - 1
			update_ship_shape()
		end,
		timeout = 10,
		color = { 70, 200, 70 }
	},
	{
		message = 'ZOOOOOOM',
		on = function()
			local x, y = world_camera:getScaleFactor()
			world_camera:setScaleFactor(x*1.2, y*1.2)
		end,
		off = function()
			local x, y = world_camera:getScaleFactor()
			world_camera:setScaleFactor(x/1.2, y/1.2)
		end,
		timeout = 10,
		color = { 150, 150, 150 }
	},
	{
		message = 'FLIP!',
		on = function()
			local x, y = world_camera:getScaleFactor()
			world_camera:setScaleFactor(x, y*-1)
		end,
		off = function()
			local x, y = world_camera:getScaleFactor()
			world_camera:setScaleFactor(x, y*-1)
		end,
		timeout = 10,
		color = { 200, 190, 80 }
	},
	]]--
	{
		message = 'REVERSE',
		on = function()
			local x, y = world_camera:getScaleFactor()
			world_camera:setScaleFactor(x*-1, y)
		end,
		off = function()
			local x, y = world_camera:getScaleFactor()
			world_camera:setScaleFactor(x*-1, y)
		end,
		timeout = 10,
		color = { 200, 90, 200 }
	}
}

-- Only used for starting period
invincible = {
	message = 'Welcome to Escape From Generic Death Star!',
	on = function() game_state.invincible = true end,
	off = function() game_state.invincible = false end,
	timeout = 5
}


