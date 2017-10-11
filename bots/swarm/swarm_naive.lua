package.path = "~\\support\\?.lua;~\\swarm\\?.lua;".. package.path
local vmath = require "vectormath"
local math = require "math"

local SwarmBase = require "swarm_base"

local ShipNaiveSwarm = {}

function ShipNaiveSwarm.new(ship, dbg, map)
	--[[ PRIVATE VARIABLES ]]--
	local self = SwarmBase.new(ship, dbg)
	local debug = dbg
	local worldmap = map

	--[[ PUBLIC VARIABLES ]]--
	self.formation_radius = 100
	self.separation_radius = 50
	self.target_x = 0
	self.target_y = 0

	--[[ PRIVATE METHODS ]]--
	local function cohesionControl()
		local dist_to_center = vmath.distance(self.fleet.x_, self.fleet.y_, self.x(), self.y())
		local vx_to_center, vy_to_center = (self.fleet.x_ - self.x()), (self.fleet.y_ - self.y())
		if dist_to_center > 0 then
			vx_to_center, vy_to_center = (vx_to_center/dist_to_center), (vy_to_center/dist_to_center)
		end

		local swarm_offsetx, swarm_offsety = self.fleet.x_ - self.formation_radius*vx_to_center, self.fleet.y_ - self.formation_radius*vy_to_center

		local cohesion_mag = vmath.distance(self.x(), self.y(), swarm_offsetx, swarm_offsety)
		local cohesion_vx, cohesion_vy = (swarm_offsetx - self.x()), (swarm_offsety - self.y())
		if cohesion_mag > 0 then
			-- unit vector to the center of the swarm
			cohesion_vx, cohesion_vy = (cohesion_vx/cohesion_mag), (cohesion_vy/cohesion_mag)
		else
			cohesion_vx, cohesion_vy = 0,0
		end

		return cohesion_vx, cohesion_vy, cohesion_mag
	end -- end cohesionControl

	local function avoidanceControl()
		local dist_to_wall, wallpoint, wall, wallnorm = worldmap.nearestwall({self.x(), self.y()})
		local angle_to_wall, _ = vmath.cart2polar(wallpoint[1]-self.x(), wallpoint[2]-self.y())

		local separation_vx, separation_vy = 0,0

		if dist_to_wall < self.separation_radius then
			local scale = 0 --1 + 10*(1-vmath.sigmoid(dist_to_wall))
			separation_vx, separation_vy = scale*wallnorm[1], scale*wallnorm[2]
		end

		for i, nbr in pairs(self.neighbors) do
			-- use vector from neighbor to ship (points away from neighbor)
			-- the smaller the magnitude, the more you want to move away..
			local sep_x = nbr.distance / (self.x()-nbr.ship.x())
			local sep_y = nbr.distance / (self.y()-nbr.ship.y())
			if nbr.distance < self.separation_radius then
				local scale = 1 + 10*(1-vmath.sigmoid(nbr.distance))
				separation_vx, separation_vy = separation_vx + scale*sep_x, separation_vy + scale*sep_y
			end
		end

		local separation_mag = vmath.distance(separation_vx, separation_vy, 0, 0)
		if separation_mag > 0 then
			separation_vx, separation_vy = (separation_vx/separation_mag), (separation_vy/separation_mag)
		else
			separation_vx, separation_vy = 0, 0
		end

		return separation_vx, separation_vy, separation_mag
	end -- end avoidanceControl

	local function objectiveControl()
		--[[
			equation for a circle centered at k,h: (x-k)^2 + (y-h)^2 = r^2
			equation for a line between two points: y = (y2-y1)/(x2-x1) * (x-x1) + y1
			find intersection given r, k,h = x2,y2 and x1,y1
			actually, since r is known, we just need a distance r away from x2, y2 on this line..
		]]--
		-- vector from fleet center to ship
		local vx_to_center, vy_to_center = (self.fleet.x_ - self.ship:x()), (self.fleet.y_ - self.ship:y())
		local vec_mag_to_center = vmath.distance(self.ship:x(), self.ship:y(), self.fleet.x_, self.fleet.y_)
		if vec_mag_to_center > 0 then
			vx_to_center, vy_to_center = (vx_to_center/vec_mag_to_center), (vy_to_center/vec_mag_to_center)
		end

		local formation_tgt_x, formation_tgt_y = (self.ship:x()+(vec_mag_to_center-self.formation_radius)*vx_to_center), (self.ship:y()+(vec_mag_to_center-self.formation_radius)*vy_to_center)
		local swarm_offx, swarm_offy = (self.ship:x() - self.fleet.x_), (self.ship:y() - self.fleet.y_)
		-- local tgt_x_corr, tgt_y_corr = self.target_x + swarm_offx, self.target_y + swarm_offy

		local tgt_x_corr, tgt_y_corr = self.target_x - (self.formation_radius*vx_to_center), self.target_y - (self.formation_radius*vy_to_center)
		debug:drawCircle(tgt_x_corr, tgt_y_corr, 4, {a=0}, 2, {b=200})

		local objective_mag = vmath.distance(tgt_x_corr, tgt_y_corr, self.ship:x(), self.ship:y())
		local objective_vx, objective_vy = (tgt_x_corr - self.ship:x()), (tgt_y_corr - self.ship:y())

		if objective_mag > 0 then
			objective_vx, objective_vy = (objective_vx/objective_mag), (objective_vy/objective_mag)
		else
			objective_vx, objective_vy = 0,0
		end

		return objective_vx, objective_vy, objective_mag
	end -- end objectiveControl

	local function alignmentControl()
		local ship_xdot, ship_ydot = vmath.polar2cart(self.ship:heading(), self.ship:speed())
		local alignment_mag = vmath.distance(self.fleet.xdot_, self.fleet.ydot_, ship_xdot, ship_ydot)
		local alignment_vx, alignment_vy = (self.fleet.xdot_ - ship_xdot), (self.fleet.ydot_ - ship_ydot)

		if alignment_mag > 0 then
			alignment_vx, alignment_vy = (alignment_vx/alignment_mag), alignment_vy/alignment_mag
		else
			alignment_vx, alignment_vy = 0, 0
		end

		return alignment_vx, alignment_vy, alignment_mag
	end -- end alignmentControl

	local function calculateControlAction()
		local co_vx, co_vy, co_mag = cohesionControl()
		local av_vx, av_vy, av_mag = avoidanceControl()
		local ob_vx, ob_vy, ob_mag = objectiveControl()
		local al_vx, al_vy, al_mag = alignmentControl()

		local cohesion_sf = 10* co_mag / ob_mag -- ratio of cohesion vs objective
		local objective_sf = ob_mag / co_mag -- ratio of objective vs cohesion (focus on objective if farther away)
		local avoidance_sf = cohesion_sf + objective_sf -- prioritize avoidance
		local alignment_sf = 0 -- (cohesion_sf + objective_sf + avoidance_sf) / 3

		local vx = cohesion_sf*co_vx + avoidance_sf*av_vx + objective_sf*ob_vx + alignment_sf*al_vx
		local vy = cohesion_sf*co_vy + avoidance_sf*av_vy + objective_sf*ob_vy + alignment_sf*al_vy
		local mag = vmath.distance(vx, vy, 0, 0)

		if mag > 0 then
			vx, vy = vx/mag, vy/mag
		else
			vx, vy = 0, 0
		end

		return vx, vy
	end

	--[[ PUBLIC METHODS ]]--
	function self.run() -- overrides base class
		ux, uy = calculateControlAction()
		self._innerVelocityControl(ux, uy)
	end

	--[[ INITIALIZATION EXECUTION ]]--

	return self
end

return ShipNaiveSwarm