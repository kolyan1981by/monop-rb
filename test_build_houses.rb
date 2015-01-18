require_relative "utils"
require_relative "game"
require_relative  'game_manager'
require_relative "player"
require_relative "player_steps"


puts "---test trade func"

g = Game.new(File.dirname(__FILE__))
g.auto_update = false
g.log_console = true
g.add_players(2,3000)
g.start

p = g.curr
p.pos = 5

h = [2,2,2,2,2]
m = [5,15]
[6,8,9,5,15].each_with_index do |id, ind|
    c = g.cells[id]
    c.owner = 0
    c.houses_count = h[ind] if c.type==1

    c.ismortgage = true if m.include? id
end

g.map.update_map


available_money = 3000
tobuy = g.cells[31]

puts "------"
p g.player_assets(p.id)
p BotActionsWhenBuy.factor_of_buy(g,p,tobuy)

=begin
groupCells = g.map.cells_by_user_by_type(p.id, 1).select{|c| c.monopoly?}.group_by(&:group)
.select{|k,v|  v.all?{|c| c.active?} }

groupCells.sort_by{|k,v| v.max_by(&:houses_count).houses_count}.reverse.each do |gr|
p gr
end
--------------------
sum = 0.7*g.player_assets(0,false)
BBHouses.build_houses(g,sum)
g.info


--------------------
myGroupsWithHouses = BBHouses.get_groups_where_need_build_houses(g,p.id)

p myGroupsWithHouses.map{ |gh|
            arr = BotActionsWhenBuy.mygroups_with_max_housecount(gh[0], gh[1])
            mf = arr.detect{|f| f[0] > available_money }
            puts "#{mf}"
            mf.nil? ? -1 : mf[1]
         }.min

=end
