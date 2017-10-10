-- A battle ship that just moves back and forth and shoots at any enemy it sees.
package.path = "~\\support\\?.lua;~\\swarm\\?.lua;".. package.path
math = require "math"
vmath = require "vectormath"
map = require "map"

ShipSwarmBehavior = require "swarm_behavior"

ship_type = ShipSwarmBehavior

fleet = nil
ship = nil
world = nil
worldmap = nil
gfx = nil

time = 0
fleet_mean_x = 0
fleet_mean_y = 0

separation_radius = 100
waypoint_spacing = 100

function init(shipArg, worldArg, gfxArg)
	fleet = {}
	world = worldArg
	gfx = gfxArg
	worldmap = map.new(world)

	if world:teamSize() > 1 then
		for i, s in pairs(shipArg) do
			table.insert(fleet, ship_type.new(s, gfx, worldmap))
		end

		ship = fleet[1]
		-- ship:setName("Captain")
	else
		ship = ship_type.new(shipArg, gfx, worldmap)
		fleet = {ship}
	end

	target_x = math.random(100, worldmap.width - 100)
	target_y = math.random(100, worldmap.height - 100)
end

function run(enemyShips)
	time = world:time()
	calculate_fleet_motion()

	if vmath.distance(fleet_mean_x, fleet_mean_y, target_x, target_y) < 100 then
		target_x = math.random(100, worldmap.width - 100)
		target_y = math.random(100, worldmap.height - 100)
	end

	for i, s in pairs(fleet) do
		s.target_x = target_x
		s.target_y = target_y
		s.run()
	end

	gfx:drawCircle(target_x, target_y, 10, {a=0}, 3, {g=255}) -- waypoint location
end

function calculate_fleet_motion()
	-- Since this lua file has access to all ships, we'll save on computation time and just calculate fleet wide numbers once
	-- for all ships to use.
	fleet_mean_x, fleet_mean_y = 0, 0
	fleet_mean_xdot, fleet_mean_ydot = 0, 0

	for i, s in pairs(fleet) do
		fleet_mean_x, fleet_mean_y = fleet_mean_x + s.x() , fleet_mean_y + s.y()

		local xdot, ydot = vmath.polar2cart(s.heading(), s.speed())
		fleet_mean_xdot, fleet_mean_ydot = fleet_mean_xdot + xdot, fleet_mean_ydot + ydot

		s.neighbors = {}

		for ii, other in pairs(fleet) do
			if s ~= other then
				local dist = vmath.distance(s.x(), s.y(), other.x(), other.y())
				table.insert(s.neighbors, {['ship']=other, ['distance']=dist})
			end
		end
	end

	fleet_mean_x, fleet_mean_y = (fleet_mean_x / #fleet) , (fleet_mean_y / #fleet)
	fleet_mean_xdot, fleet_mean_ydot = (fleet_mean_xdot / #fleet) , (fleet_mean_ydot / #fleet)

	for i, s in pairs(fleet) do
		s.fleet.x_, s.fleet.y_ = fleet_mean_x , fleet_mean_y
		s.fleet.xdot_, s.fleet.ydot_ = fleet_mean_xdot , fleet_mean_ydot
	end
end
