
function pop(stream)

	if stream.top.x < stream.bottom.x then
		side = 'top'
		oldpos = stream.top
		newpos = { x=oldpos.x + math.random(50, 200), y=math.random(-100, 100) }
		base = top
		y0 = -150
	else
		side = 'bottom'
		oldpos = stream.bottom
		newpos = { x=oldpos.x + math.random(50, 200), y=math.random(-100, 100) }
		base = ground
		y0 = 150
	end

	shape = love.physics.newPolygonShape(base,
		oldpos.x, y0,
		oldpos.x, oldpos.y,
		newpos.x, newpos.y,
		newpos.x, y0
		)

	stream[side] = newpos

	return {
		border_shapes = {
				shape
			},
		rightmost_x = newpos.x,
		obsolete = function(self)
				return self.rightmost_x < -top:getX()
			end
	}
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

