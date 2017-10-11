package.path = "~\\support\\?.lua;~\\swarm\\?.lua;".. package.path
local vmath = require "vectormath"
local math = require "math"

local SwarmBase = require "swarm_base"

local ShipArtificialForces = {}

--[[
	This package implements the formation control methods for a swarm outlined in the paper
		Formation Control of Robotic Swarm Using Bounded Artificial Forces
		by ??? et al.
]]--

function ShipArtificialForces.new(ship, dbg, map)
	--[[ PRIVATE VARIABLES ]]--
	local self = SwarmBase.new(ship, dbg)
	local debug = dbg
	local worldmap = map

	--[[ PUBLIC VARIABLES ]]--
	self.m = 1
	self.b = 1

	self.k_a = 1.5
	self.k_r = 1
	self.k_m = 1

	self.beta_a = 1
	self.beta_r = 1
	self.beta_m = 1

	-- table of table for points on target shape (given by main controller) -> (x, y, unit vec pointint out)
	self.target_shape = {{}}
	self.dz = 1 -- unit length for discretization of shape integral
	self.zx_c = 0 -- target shape center x
	self.zy_c = 0 -- target shape center y

	--[[ PRIVATE METHODS ]]--
	local function is_in_formation()
		for i, z in pairs(self.target_shape) do
			local vx_to_z, vy_to_z, _ = vmath.unitvec(self.ship:x(), ship.ship:y(), z[1], z[2])
			local target_angle, _ = vmath.cart2polar(z[3]-vx_to_z, z[4]-vy_to_z)
			if math.abs(target_angle) < math.pi/2.0 then
				return true
			end
		end
	end

	-- All force compoenents are of the form F(k, beta) = k*exp(-beta*x)
	local function F_i_a()
		--[[
			Attraction force on the i-th robot from the shape denoted l
		]]--
		local fx_a, fy_a = 0,0

		for i, z in pairs(self.target_shape) do
			-- get unit vector from robot to point on shape (z - x_i)
			local vz_x, vz_y, vz_mag = vmath.unitvec(self.ship:x(), self.ship:y(), z[1], z[2])
			local f_mag = (1 - math.exp(-self.beta_a*vz_mag))
			fx_a = fx_a + vz_x*f_mag*self.dz
			fy_a = fy_a + vz_y*f_mag*self.dz
		end
		fx_a, fy_a = self.k_a*fx_a, self.k_a*fy_a
		return fx_a, fy_a
	end

	local function F_i_r()

	end

	local function F_i_m()

	end

	local function F_i_o()

	end

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

	--[[ INITIALIZATION EXECUTION ]]--

	return self
end

return ShipArtificialForces