local math = require "math"

local vmath = {}

function vmath.sigmoid(z)
	return 1 / (1+math.exp(-z / 50))
end

function vmath.square(x)
	return x*x
end

function vmath.distance(x1, y1, x2, y2)
	return math.sqrt(vmath.square(x1-x2) + vmath.square(y1-y2))
end

function vmath.cart2polar(x, y)
	return math.atan2(y, x), math.sqrt(vmath.square(x)+vmath.square(y))
end

function vmath.polar2cart(ang, rad)
	return rad*math.cos(ang), rad*math.sin(ang)
end

function vmath.dotproduct(x1, y1, x2, y2)
	return x1*x2 + y1*y2
end

function vmath.unitvec(x1, y1, x2, y2)
	local vx, vy = x2-x1, y2-y1
	local mag = vmath.distance(x1,y1,x2,y2)
	if mag > 0 then
		vx, vy = vx/mag, vy/mag
	else
		vx, vy = 0, 0
	end
	return vx, vy, mag
end

return vmath