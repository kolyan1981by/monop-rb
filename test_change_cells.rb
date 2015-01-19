require_relative "utils"
require_relative "game"
require_relative  'game_manager'
require_relative "player"
require_relative "player_steps"


puts "---test trade func"

g = Game.new(File.dirname(__FILE__))
#g.debug =true
g.update_interval =0.01
g.add_players(2,10000)

g.start
#GameManager.update_game(g)

g.curr.pos = 5

[9,13].each do |c|
    g.cells[c].owner = 0
end
[6,14].each do |c|
    g.cells[c].owner = 1
end

g.map.update_map

g.cells.select{|cc| cc.land?}.group_by(&:group).sort_by{|k,v| k}.each do |k,v|
    v.each do |cl|
      pl = cl.owner ? cl.owner : " "
      p "#{pl} #{cl.name.strip.ljust(12, ' ')} rent: #{cl.rent}"
    end
end

#p BotBrainTrade.get_valid_trades(g,p)
#BotBrainTrade.try_do_trade(g)
