package.path = "~\\support\\?.lua;~\\swarm\\?.lua;".. package.path
local vmath = require "vectormath"
local math = require "math"
local map = require "map"

local SwarmBaseShip = {}

function SwarmBaseShip.new(ship, dbg)
	--[[ PRIVATE VARIABLES ]]--
	local self = {}
	local debug = dbg

	--[[ PUBLIC VARIABLES ]]--
	self.ship = ship
	self.neighbors = {{['ship']=nil, ['distance']=0}}
	self.fleet = {
		['x_']=0, ['y_']=0,
		['xdot_']=0, ['ydot_']=0
	}

	--[[ PRIVATE METHODS ]]--
	function self._innerVelocityControl(tgt_xdot, tgt_ydot)
		local ship_vx, ship_vy = vmath.polar2cart(self.ship:heading(), self.ship:speed())
		local ship_mag = math.sqrt(vmath.square(ship_vx) + vmath.square(ship_vy))
		if ship_mag > 0 then
			ship_vx, ship_vy = (ship_vx/ship_mag) , (ship_vy/ship_mag)
		end
		local err_vx, err_vy = (tgt_xdot-ship_vx) , (tgt_ydot-ship_vy)
		local ctrl_angle, ctrl_spd = vmath.cart2polar(err_vx, err_vy)
		self.ship:fireThruster(ctrl_angle, 5*ctrl_spd)
	end -- end innerVelocityControl

	--[[ PUBLIC METHODS ]]--
	function self.x() return self.ship:x() end
	function self.y() return self.ship:y() end
	function self.heading() return self.ship:heading() end
	function self.speed() return self.ship:speed() end

	function self.run()
		self._innerVelocityControl(0, 0)
	end

	--[[ INITIALIZATION EXECUTION ]]--


	return self
end

return SwarmBaseShip