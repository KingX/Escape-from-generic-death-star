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
			end,
		update = function(self, dt)
				for i = 1,3 do
					r = math.random(-10, 10)
					if self.color[i] >= 245 then
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
				return self.body:getX() < -100 or self.body:getY() > 700
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
				love.graphics.setColor(180, 180, 180)
				love.graphics.polygon(love.draw_fill, self.shape:getPoints())
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
	local msg, on, off, timeout = 10

	if math.random(0, 100) <= item_chance then
		local x = math.random(0, 100)

		if x < 10 then
			msg = "ZACK! Control inversion"
			on = function(self) invert_controls = true end
			off = function() invert_controls = false end

		elseif x < 20 then
			msg = "SPEED BLAST"
			on = function(self) speed = 200 end
			off = function() speed = 100 end

		else
			msg = "CA$H"
			timeout = 1.0
			on = function(self) score = score + 10000 end
			off = function() end

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

