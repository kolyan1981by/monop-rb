require_relative "utils"
require_relative "game"
require_relative  'game_manager'
require_relative "player"
require_relative "player_steps"

g = Game.new(File.dirname(__FILE__))
p g.community_chest
exit

file = "data/chest_cards.txt"
res = []

File.open(file, "r").drop(1).each do |line|
    next if /\S/ !~ line

    v = line.split("\t").select{ |e| !e.strip.empty?  }
    cc =ChestCard.new
    cc.random_group =v[0].to_i
    cc.type =v[1].to_i
    cc.text =v[2]
    cc.money =v[3].to_i if v.size >=4
    cc.pos =v[4].to_i if v.size >=5
    res<< cc
end
p res.select{ |e| e.type ==2 }.map { |e| [e.random_group , e.text, e.pos]  }
