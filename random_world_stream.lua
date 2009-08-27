-- vim: set noexpandtab:

function _create_item_canon(stream)
	local x = 1000
	local y 
	local shot_interval = .6
	local speed = 0.4
	local radius = 20
	local len = 50
	local d = 150
	local side
	if math.random(1, 2) == 1 then
		side = 'top'
	end
	if side == 'top' then
		y = 600 - d
		offset = {x=-len, y=-len}
	else
		y = d
		offset = {x=-len, y=len}
	end

	r = {
		kind = 'canon',
		x = x,
		y = y,
		time_since_last_shot = 0,
		offset = offset,
		shot_interval = shot_interval,
		radius = radius,
		draw = function(self)
			love.graphics.setLineWidth(2)

			love.graphics.setColor(90, 90, 90)
			love.graphics.polygon(love.draw_fill, self.x, self.y+10, self.x, self.y-10, self.x+offset.x, self.y+offset.y)
			love.graphics.setColor(120, 120, 120)
			love.graphics.polygon(love.draw_line, self.x, self.y+10, self.x, self.y-10, self.x+offset.x, self.y+offset.y)

			love.graphics.setColor(90, 90, 90)
			love.graphics.circle(love.draw_fill, self.x, self.y, self.radius)
			love.graphics.setColor(120, 120, 120)
			love.graphics.circle(love.draw_line, self.x, self.y, self.radius)
		end,
		speed = speed,
		update = function(self, dt)
			self.x = self.x - dt * effect_state.speed * self.speed
			self.time_since_last_shot = self.time_since_last_shot + dt
			if self.time_since_last_shot >= shot_interval then
				it = _create_random_item(self.x+self.offset.x, self.y+self.offset.y)
				it.body:setVelocity(-effect_state.speed * (1 + self.speed), self.offset.y)
				table.insert(stream_items, it)
				self.time_since_last_shot = 0
			end
		end,
		obsolete = function(self)
			local r = self.x < (-2 * d)
			if r then
				debug(string.format("cannon at %d is obsolete!", self.x))
			end
			return r
		end
	}
	return r
end

function _create_item(message, effect_on, effect_off, timeout, x, y)
	local body = love.physics.newBody(world, x, y, 0.01)
	local shape = love.physics.newPolygonShape(body,
		-10, -10, 10, -10, 10, 10, -10, 10
		)
	r = {
		shape = shape,
		body = body,
		color = { 128, 128, 128 },
		draw = function(self)
				love.graphics.setColor(self.color[1], self.color[2], self.color[3])
				love.graphics.polygon(love.draw_fill, self.shape:getPoints())
				love.graphics.setColor(self.color[1] + 40, self.color[2] + 40, self.color[3] + 40)
				love.graphics.polygon(love.draw_line, self.shape:getPoints())
			end,
		update = function(self, dt)
				for i = 1,3 do
					r = math.random(-10, 10)
					if self.color[i] >= 200 then
						r = -math.abs(r)
					elseif self.color[i] <= 20 then
						r = math.abs(r)
					end
					self.color[i] = self.color[i] + r
				end
			end,
		effect_message = message,
		effect_on = effect_on,
		effect_off = effect_off,
		effect_timeout = timeout,
		obsolete = function(self)
				return (self.body:getX() < -100) or (self.body:getY() > 700)
			end,
		collision_type = 'item'
	}
	shape:setData(r)
	return r
end

function _create_border_piece(stream, side, oldpos)
	local newpos, base, y0
	if side == 'top' then
		newpos = { x=oldpos.x + math.random(50, 200), y=math.random(-100, 100) }
		base = top
		y0 = -150
	else
		newpos = { x=oldpos.x + math.random(50, 200), y=math.random(-100, 100) }
		base = ground
		y0 = 150
	end

	local shape = love.physics.newPolygonShape(base,
		oldpos.x, y0,
		oldpos.x, oldpos.y + math.random(-10, 10),
		newpos.x, newpos.y,
		newpos.x, y0
		)

	stream[side] = newpos

	local r = math.random(100, 120)
	local gadd = math.random(2, 7)
	local badd = math.random(2, 7)
	local color = {
				[0] = r,
				[1] = r + gadd,
				[2] = r + gadd + badd
		}
	local r = {
		color = color,
		collision_type = 'border',
		shape = shape,
		left_y = oldpos.y,
		draw = function(self)
				--love.graphics.setColor(80, 90, 100)
				love.graphics.setLineWidth(1)
				love.graphics.setColor(self.color[0], self.color[1], self.color[2])
				love.graphics.polygon(love.draw_fill, self.shape:getPoints())
				love.graphics.setColor(self.color[0] - 20, self.color[1] - 20, self.color[2] - 20)
				--love.graphics.setColor(140, 150, 160)
				love.graphics.polygon(love.draw_line, self.shape:getPoints())
				local ps = {self.shape:getPoints()}
				-- find points that should carry the outline
				local line_ps = {}
				local left_x = nil
				local left_y_high = 0
				love.graphics.setLineWidth(3)
				for i = 0, 3 do
					if ps[i*2+2] ~= 0 and ps[i*2+2] ~= 600 then
						table.insert(line_ps, ps[i*2+1])
						table.insert(line_ps, ps[i*2+2])
					end
				end
				--table.foreach(line_ps, print)
				--love.graphics.setColor(120, 120, 120)
				if #line_ps == 4 then
					love.graphics.line(line_ps[1], line_ps[2], line_ps[3], line_ps[4])
				end
				love.graphics.setLineWidth(1)
			end,
		rightmost_x = newpos.x,
		obsolete = function(self)
				return self.rightmost_x < -top:getX()
			end
	}
  shape:setData(r)
  return r
end

function _create_random_item(x, y)
	local rnd = math.random(0, 60)
	local timeout = 10

	if rnd < 0 then
		msg = "GRAVITY BLAST"
		on = function(self) effect_state.inverted_controls = not effect_state.inverted_controls end
		off = function() effect_state.inverted_controls = not effect_state.inverted_controls end

	elseif rnd < 40 then
		msg = "SPEED BLAST"
		on = function(self) effect_state.speed = effect_state.speed * 2 end
		off = function() effect_state.speed = effect_state.speed / 2 end

		elseif x < 50 then
			msg = "LOL BACKWARDS BLAST"
			on = function(self) effect_state.speed = effect_state.speed * -1 end
			off = function() effect_state.speed = effect_state.speed * -1 end

	elseif rnd < 60 then
		msg = "BIG BLAST"
		on = function(self)
			effect_state.ship_size = effect_state.ship_size * 2
			local sz = effect_state.ship_size
			ship_shape:setData(nil)
			ship_shape:destroy()
			ship_shape = love.physics.newPolygonShape(ship, 0, 0, 50 * sz, 15 * sz, 0, 30 * sz)
			ship_shape:setData({collision_type = 'ship'})
		end
		off = function()
			effect_state.ship_size = effect_state.ship_size / 2
			local sz = effect_state.ship_size
			ship_shape:setData(nil)
			ship_shape:destroy()
			ship_shape = love.physics.newPolygonShape(ship, 0, 0, 50 * sz, 15 * sz, 0, 30 * sz)
			ship_shape:setData({collision_type = 'ship'})
		end
	else
		msg = "CA$H"
		timeout = 3.0
		on = function(self)
			effect_state.score_multiplier = effect_state.score_multiplier * 10
		end
		off = function()
			effect_state.score_multiplier = effect_state.score_multiplier / 10.0
		end

	end
	r = _create_item(msg, on, off, timeout, x, y)
	return r
end

function pop(stream)
	local r = nil
	local item_chance = 10 -- of 100
	local canon_chance = 50
	local msg, on, off
	local timeout = 10

	local rnd = math.random(0, 100)
	if rnd <= item_chance then
		local y = math.random(200, 400)
		local x = 760
		r = _create_random_item(x, y)
		r.body:applyImpulse(-20, -10)
		r.body:setSpin(180)
	elseif rnd <= item_chance + canon_chance and not has_canon then
		debug("creating canon")
		r = _create_item_canon(stream)
		debug("done")
	else
		if stream.top.x > stream.bottom.x then side = 'bottom'
		else side = 'top' end
		r = _create_border_piece(stream, side, stream[side])
	end

	return r
end

function max_x(stream)
	return math.max(stream.top.x, stream.bottom.x)
end

function create()
	return {
		top = { x=0, y=0 },
		bottom = { x=0, y=0 },
		pop = pop,
		max_x = max_x
	}
end

return {
	create = create
}

