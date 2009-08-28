-- vim: set noexpandtab:

background = {
	class = {}
}
background.class.__index = background.class

function background.new(speed)
	local bg = {
		squares = {},
		speed = speed,
		square_count = 500,
		size_min = config.resolution.x / 20,
		size_max = config.resolution.x / 10,
		grey_min = 75,
		grey_max = 80
	}
	setmetatable(bg, background.class)
	bg:init()
	return bg
end

function background.class:init()
	x0, y0, x1, y1 = get_visible_area()
	self.squares = {}
	for i=1,self.square_count do
		table.insert(self.squares, {
			x = math.random(x0, x1+(x1-x0)),
			y = math.random(y0-(y1-y0), y1+(y1-y0)),
			size = math.random(self.size_min, self.size_max),
			grey = math.random(self.grey_min, self.grey_max)
		})
	end
end

function background.class:draw()
	for i, sq in ipairs(self.squares) do
		love.graphics.setColor(sq.grey, sq.grey, sq.grey)
		love.graphics.rectangle(love.draw_fill, sq.x-sq.size, sq.y-sq.size, 2*sq.size, 2*sq.size)
	end
end

function background.class:update(dt)
	x0, y0, x1, y1 = get_visible_area()
	for i,sq in ipairs(self.squares) do
		sq.x = sq.x + self.speed * dt
		if self.speed > game_state.speed and sq.x - sq.size > x1 then
			sq.x = math.random(x0-(x1-x0), x0-self.size_max)
			sq.y = math.random(y0-(y1-y0), y1+(y1-y0))
			sq.size = math.random(self.size_min, self.size_max)
			sq.grey = math.random(self.grey_min, self.grey_max)
		elseif self.speed < game_state.speed and sq.x + sq.size < x0 then
			sq.x = math.random(x1+self.size_max, x1+(x1-x0))
			sq.y = math.random(y0-(y1-y0), y1+(y1-y0))
			sq.size = math.random(self.size_min, self.size_max)
			sq.grey = math.random(self.grey_min, self.grey_max)
		end
	end
end

parallax = {
	class = {}
}
parallax.class.__index = parallax.class

function parallax.new(speed)
	local p = {
		squares = {},
		speed = speed,
		square_count = 500,
		size_min = config.resolution.x / 20,
		size_max = config.resolution.x / 10,
		height_max = config.resolution.y * 0.4,
		grey_min = 65,
		grey_max = 70
	}
	setmetatable(p, parallax.class)
	p:init()
	return p
end

function parallax.class:init()
	x0, y0, x1, y1 = get_visible_area()
	local s_max = self.size_max
	self.squares = {}
	for i=1,self.square_count/2 do
		local square = {
			x = math.random(x0, x1 + (x1-x0)),
			y = math.random(y0-(y1-y0), y0+self.height_max),
			size = math.random(self.size_min, s_max),
			grey = math.random(self.grey_min, self.grey_max)
		}
		table.insert(self.squares, square)
	end
	for i=self.square_count/2+1,self.square_count do
		local square = {
			x = math.random(x0, x1 + (x1-x0)),
			y = math.random(y1-self.height_max, y1+(y1-y0)),
			size = math.random(self.size_min, s_max),
			grey = math.random(self.grey_min, self.grey_max)
		}
		table.insert(self.squares, square)
	end
end

function parallax.class:draw()
	for i, sq in ipairs(self.squares) do
		love.graphics.setColor(sq.grey, sq.grey, sq.grey)
		love.graphics.rectangle(love.draw_fill, sq.x, sq.y, sq.size, sq.size)
	end
end

function parallax.class:update(dt)
	x0, y0, x1, y1 = get_visible_area()
	local s_max = self.size_max
	for i=1,self.square_count do
		local sq = self.squares[i]
		sq.x = sq.x + dt * self.speed
		if sq.x+sq.size < x0 then
			if i <= self.square_count / 2 then
				sq = {
					x = math.random(x1+s_max, x1+(x1-x0)),
					y = math.random(y0-(y1-y0), y0+self.height_max),
					size = math.random(self.size_min, s_max),
					grey = math.random(self.grey_min, self.grey_max)
				}
			else
				sq = {
					--x = math.random(x0-(x1-x0), x0-s_max),
					x = math.random(x1+s_max, x1+(x1-x0)),
					y = math.random(y1-self.height_max, y1+(y1-y0)),
					size = math.random(self.size_min, s_max),
					grey = math.random(self.grey_min, self.grey_max)
				}
			end
			self.squares[i] = sq
		end
	end
end

