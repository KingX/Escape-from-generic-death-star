-- vim: set noexpandtab:

--[[
	An execption-catching wrapper for functions use as

	safe_version = makesafe(unsafe_version)
	]]
function makesafe(f)
	function f1(...)
		ok, r = pcall(f, ...)
		if not ok then
			print(r)
			os.exit(1)
		end
		return r
	end
	return f1
end

function get_visible_area()
	local ox, oy = getCamera():getOrigin()
	local sx, sy = 1, 1 --getCamera():getScaleFactor()
	return ox - config.resolution.x * sx / 2,
		oy - config.resolution.y * sy / 2,
		ox + config.resolution.x * sx / 2,
		oy + config.resolution.y * sy / 2
end

cos = function(a) return math.cos(math.rad(a % 360)) end
sin = function(a) return math.sin(math.rad(a % 360)) end

