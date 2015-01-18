require_relative "utils"
require_relative "game"
require_relative  'game_manager'
require_relative "player"
require_relative "player_steps"


puts "---test trade func"

g = Game.new(File.dirname(__FILE__))
g.debug =true
g.add_players(2,10000)
g.start

p = g.curr
p.pos = 5

[9,13].each do |c|
    g.cells[c].owner = 0
end
[6,14].each do |c|
    g.cells[c].owner = 1
end

g.map.update_map

#p BotBrainTrade.get_valid_trades(g,p)
BotBrainTrade.try_do_trade(g)
