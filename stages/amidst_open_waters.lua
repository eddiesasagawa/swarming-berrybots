-- A basic battle field with no walls.
--
-- Sample battle ships: Chaser, FloatingDuck, MyFirstShip, RandomBot,
-- WallHugger, and BasicBattler.

require "battlestage"

function configure(stageBuilder)
  stageBuilder:setSize(3000, 1500)
  stageBuilder:setBattleMode(true)
  stageBuilder:setTeamSize(10)
  stageBuilder:addStart(1500, 750)
end

ships = nil
world = nil
admin = nil

function init(shipsArg, worldArg, adminArg)
  ships = shipsArg
  world = worldArg
  admin = adminArg
end

function run(stageSensors)
  battlestage.basicScoring(ships, world, admin)
end
