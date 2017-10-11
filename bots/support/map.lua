require "math"

local map = {}
--[[
	A wall has left, bottom, width, height parameters
]]

function map.new(world)
	local self = {}

	-- Public variables
	self.walls = world:walls()
	self.width = world:width() 		-- x coordinate
	self.height = world:height()	-- y coordinate

	self.corners = {}

	-- self.iscorner -- may need to forward declare?

	-- Private methods
	local function norm(p1, p2)
		return math.sqrt((p2[1]-p1[1])^2 + (p2[2]-p1[2])^2)
	end -- end function norm

	local function loadmap()
		-- Extract wall data from world and create an occupancy map
		for i, w in pairs(self.walls) do
			-- extract all corners in map to determine smallest grid size
			if not self.iscorner({w.left, w.bottom					}) then table.insert(self.corners, {w.left, w.bottom}) end
			if not self.iscorner({w.left, w.bottom+w.height			}) then table.insert(self.corners, {w.left, w.bottom+w.height}) end
			if not self.iscorner({w.left+w.width, w.bottom			}) then table.insert(self.corners, {w.left+w.width, w.bottom}) end
			if not self.iscorner({w.left+w.width, w.bottom+w.height	}) then table.insert(self.corners, {w.left+w.width, w.bottom+w.height}) end
		end
	end -- end function loadmap

	-- Public methods
	function self.iscorner(point)
		-- check if self.corners contains the indicated corner
		for i, v in pairs(self.corners) do
			if point == v then return true end
		end
		return false
	end

	function self.nearestwall(point)
		-- find coordinate and distance of nearest wall
		local min_dist = math.huge
		local min_wall = {}
		local min_norm = {}
		local min_x = nil
		local min_y = nil
		-- first find the line that is closest to the point (each line is a side of the wall with inf length)
		for i, w in pairs(self.walls) do
			local corners = {
				{w.left, w.bottom},					-- bottom left corner
				{w.left, w.bottom+w.height},		-- top left corner
				{w.left+w.width, w.bottom},			-- bottom right corner
				{w.left+w.width, w.bottom+w.height}	-- top right corner
			}
			local walls = {
				{corners[1], corners[2]}, -- left wall
				{corners[1], corners[3]}, -- bottom wall
				{corners[2], corners[4]}, -- top wall
				{corners[3], corners[4]}  -- right wall
			}

			-- a point can only be closest to one horizontal wall and one vertical wall
			--  (if in the middle, you can just pick any one wall)
			-- so use a corner to check one first
			local verticalwall = {}
			local vertnorm = {}
			local horizontalwall = {}
			local horiznorm = {}

			if norm(point, walls[1][1]) >= norm(point, walls[4][1]) then
				verticalwall = walls[4]
				vertnorm = {1,0}
			else
				verticalwall = walls[1]
				vertnorm = {-1, 0}
			end

			if norm(point, walls[2][1]) >= norm(point, walls[3][1]) then
				horizontalwall = walls[3]
				horiznorm = {0, 1}
			else
				horizontalwall = walls[2]
				horiznorm = {0, -1}
			end

			-- now find closest point on both lines, and pick closest
			-- on horizontal wall, the normal vector is vertical
			--   p + k*<0, 1> = wall[1] + j*<1,0>
			--		p_x = corner_x + j
			--		p_y + k = corner_y  << only need this equation
			local k = horizontalwall[1][2] - point[2]
			point_h = {point[1], point[2]+k}
			-- cap to within corners
			if point_h[1] <= horizontalwall[1][1] then
				point_h = horizontalwall[1]
			elseif point_h[1] >= horizontalwall[2][1] then
				point_h = horizontalwall[2]
			end

			-- on vertical wall:
			--    p + u*<1, 0> = wall[1] + v*<0, 1>
			--		p_x + u = corner_x
			--		p_y = corner_y + v
			local u = verticalwall[1][1] - point[1]
			point_v = {point[1]+u, point[2]}
			-- cap to corners
			if point_v[2] <= verticalwall[1][2] then
				point_v = verticalwall[1]
			elseif point_v[2] >= verticalwall[2][2] then
				point_v = verticalwall[2]
			end

			-- now pick shorter distance
			local closestwall
			local closestnorm
			local closestpoint
			if norm(point, point_h) < norm(point, point_v) then
				closestwall = horizontalwall
				closestpoint = point_h
				closestnorm = horiznorm
			else
				closestwall = verticalwall
				closestnorm = vertnorm
				closestpoint = point_v
			end

			local current_dist = norm(point, closestpoint)
			if current_dist < min_dist then
				min_dist = current_dist
				min_wall = closestwall
				min_norm = closestnorm
				min_x = closestpoint[1]
				min_y = closestpoint[2]
			end
		end


		return min_dist, {min_x, min_y}, min_wall, min_norm
	end

	-- Apply some private methods
	loadmap()

	return self
end


return map