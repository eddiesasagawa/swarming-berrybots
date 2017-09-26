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