require_relative "utils"
require_relative "game"
require_relative "game_control"
def init_game
    g = Game.new(File.dirname(__FILE__))
    g.log_to_console = true
    g.add_players(2,5000)

    g.start
    g
end
def  test_auction
    g = init_game
    PlayerStep.make_step_roll(g,2,3)
    g.to_auction
    AuctionManager.run_action_job(g,"n")
end

def test_build_houses
    g = init_game
    p = g.curr
    p.pos = 5

    h = [0,0,0,0,0,0,0]
    m = [6,5,15]

    [6,8,9,11,13,14,16,18,21,23,5,15].each_with_index do |id, ind|
        c = g.cells[id]
        c.owner = 0
        #c.houses_count = h[ind] if c.type==1
        c.ismortgage = true if m.include? id
    end
    g.map.update_map

    BBCells.unmortgage_cells(g)

    groups = g.map.monop_groups_by_user(0)


    sum = 0.7*g.player_assets(0,false)

    BBHouses.build_houses(g,sum)

    p GameUI.player_houses_info g
    p g.logs
end

test_build_houses

=begin

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

def test_trade
    puts "---test trade func"

    g= init_game
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
end
#p BotBrainTrade.get_valid_trades(g,p)
#BotBrainTrade.try_do_trade(g)
