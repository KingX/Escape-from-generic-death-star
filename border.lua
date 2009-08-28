-- vim: set noexpandtab:

border = { class={} }
border.class.__index = border.class

--[[
	d = relative minimal distance between top and bottom
			(1.0=one screen height)
	w = relative width of pieces (1.0=one screen width)
	c = relative maximal height change (1.0=one screen height)
	]]
function border.new(d, w, c)
	local b = {
		piece_width = w * config.resolution.x,
		min_distance = d * config.resolution.y,
		max_distance = 5 * d * config.resolution.y,
		max_change = c * config.resolution.y,
		rightmost_idx = nil,
		cannon_chance = 0.1,
		cannon_interval = 1.0
	}
	b.body = love.physics.newBody(world, 0, 0, 0)
	setmetatable(b, border.class)
	b:init()
	return b
end

--[[
	Given a border element 'prev' generate and return an adjacent border element.
	]]
function border.class:create_element(prev)
	local top_x = prev.top.x + self.piece_width
	local top_y = prev.top.y + math.random(-self.max_change, self.max_change)

	-- Generate bottom, constrained by distance to top
	local bottom_x = prev.bottom.x + self.piece_width
	local bottom_y = top_y + math.random(self.min_distance, self.max_distance)

	-- Fix bottom to obey max_change (overrides distance)
	if bottom_y > prev.bottom.y + self.max_change then
		bottom_y = prev.bottom.y + self.max_change
	elseif bottom_y < prev.bottom.y - self.max_change then
		bottom_y = prev.bottom.y - self.max_change
	end

	-- Generate shapes
	local top_shape = love.physics.newPolygonShape(
		self.body,
		prev.top.x, y0 - (y1-y0), prev.top.x, prev.top.y,
		top_x, top_y, top_x, y0 - (y1 - y0)
	)
	local bottom_shape = love.physics.newPolygonShape(
		self.body,
		prev.bottom.x, y1 + (y1-y0), prev.bottom.x, prev.bottom.y,
		bottom_x, bottom_y, bottom_x, y1 + (y1 - y0)
	)

	r = {
		type = 'border',
		top = {
			x = top_x,
			y = top_y,
			shape = top_shape,
			prev_x = prev.top.x,
			prev_y = prev.top.y
		},
		bottom = {
			x = bottom_x,
			y = bottom_y,
			shape = bottom_shape,
			prev_x = prev.bottom.x,
			prev_y = prev.bottom.y
		}
	}

	r.top.shape:setData(r)
	r.top.shape:setCategory(category.border)
	r.top.shape:setMask(category.item)
	r.bottom.shape:setData(r)
	r.bottom.shape:setCategory(category.border)
	r.bottom.shape:setMask(category.item)

	-- Should we add a cannon to this border piece?
	if math.random() < self.cannon_chance then
		local pos = {
			x = (r.bottom.prev_x + r.bottom.x) / 2,
			y = (r.bottom.prev_y + r.bottom.y) / 2
		}
		local radius = self.piece_width * 0.5 / 2
		r.cannon = {
			x = pos.x, y = pos.y, r = radius,
			time_since_shot = 0,
			interval = self.cannon_interval
		}
	end

	return r
end


function border.class:init()
	self.elements = {}
	x0, y0, x1, y1 = get_visible_area()
	local prev = {
		top = { x = x0, y = y0 },
		bottom = { x = x0, y = y1 }
	}

	for x = x0,x1,self.piece_width do
		local e = self:create_element(prev)
		table.insert(self.elements, e)
		prev = e
	end
	self.rightmost_idx = #self.elements
end

function border.class:update(dt)
	x0, y0, x1, y1 = get_visible_area()
	for i, elem in ipairs(self.elements) do
		if elem.top.x < x0 then
			elem.top.shape:setData(nil)
			elem.top.shape:destroy()
			elem.bottom.shape:setData(nil)
			elem.bottom.shape:destroy()
			local e = self:create_element(self.elements[self.rightmost_idx])
			self.elements[i] = e
			self.rightmost_idx = i
		end
		if elem.cannon ~= nil then
			local l = elem.cannon.r * 2
			elem.cannon.time_since_shot = elem.cannon.time_since_shot + dt
			if elem.cannon.time_since_shot > elem.cannon.interval then
				local it = items:generate_item_at(elem.cannon.x - l, elem.cannon.y - l)
				it.body:applyImpulse(-5000000, -5000000)
				elem.cannon.time_since_shot = 0
			end
		end
	end
end

function border.class:draw()
	for i, elem in ipairs(self.elements) do
		if elem.cannon ~= nil then
			local e = self.piece_width * 0.05
			local l = elem.cannon.r * 2
			love.graphics.setColor(20, 20, 20)
			love.graphics.polygon(love.draw_fill,
				elem.cannon.x - e, elem.cannon.y + e,
				elem.cannon.x + e, elem.cannon.y - e,
				elem.cannon.x + e - l, elem.cannon.y - e - l,
				elem.cannon.x - e - l, elem.cannon.y + e -l
			)
			love.graphics.setColor(255, 255, 255)
			love.graphics.polygon(love.draw_line,
				elem.cannon.x - e, elem.cannon.y + e,
				elem.cannon.x + e, elem.cannon.y - e,
				elem.cannon.x + e - l, elem.cannon.y - e - l,
				elem.cannon.x - e - l, elem.cannon.y + e -l
			)

			love.graphics.setColor(20, 20, 20)
			love.graphics.circle(love.draw_fill, elem.cannon.x, elem.cannon.y, elem.cannon.r)
			love.graphics.setColor(255, 255, 255)
			love.graphics.circle(love.draw_line, elem.cannon.x, elem.cannon.y, elem.cannon.r)
		end

		love.graphics.setColor(20, 20, 20)
		love.graphics.polygon(love.draw_fill, elem.top.shape:getPoints())
		love.graphics.polygon(love.draw_fill, elem.bottom.shape:getPoints())
		love.graphics.setColor(255, 255, 255)
		love.graphics.line(elem.top.prev_x, elem.top.prev_y, elem.top.x, elem.top.y)
		love.graphics.line(elem.bottom.prev_x, elem.bottom.prev_y, elem.bottom.x, elem.bottom.y)
	end
end


