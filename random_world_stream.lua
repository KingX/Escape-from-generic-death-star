-- vim: set noexpandtab:

function _create_item(message, effect_on, effect_off, timeout)
	local y = math.random(200, 400)
	local x = 760
	local body = love.physics.newBody(world, x, y, 0.01)
	local shape = love.physics.newPolygonShape(body,
		0, -20, 20, 0, 0, 20, -20, 0
		)
	body:applyImpulse(-20, -10)
	body:setSpin(180)
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
		oldpos.x, oldpos.y,
		newpos.x, newpos.y,
		newpos.x, y0
		)

	stream[side] = newpos

	local r = {
		collision_type = 'border',
		shape = shape,
		draw = function(self)
				love.graphics.setColor(100, 110, 120)
				love.graphics.polygon(love.draw_fill, self.shape:getPoints())
				love.graphics.setColor(130, 140, 150)
				love.graphics.polygon(love.draw_line, self.shape:getPoints())
			end,
		rightmost_x = newpos.x,
		obsolete = function(self)
				return self.rightmost_x < -top:getX()
			end
	}
  shape:setData(r)
  return r
end

function pop(stream)
	local r = nil
	local item_chance = 10 -- of 100
	local msg, on, off
	local timeout = 10

	if math.random(0, 100) <= item_chance then
		local x = math.random(0, 60)

		if x < 0 then
			msg = "GRAVITY BLAST"
			on = function(self) effect_state.inverted_controls = not effect_state.inverted_controls end
			off = function() effect_state.inverted_controls = not effect_state.inverted_controls end

		elseif x < 40 then
			msg = "SPEED BLAST"
			on = function(self) effect_state.speed = effect_state.speed * 2 end
			off = function() effect_state.speed = effect_state.speed / 2 end

		elseif x < 60 then
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
				effect_state.score_multiplier = effect_state.score_multiplier * 4
			end
			off = function()
				effect_state.score_multiplier = effect_state.score_multiplier / 4.0
			end

		end
		r = _create_item(msg, on, off, timeout)

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

