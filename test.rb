require_relative "utils"
require_relative "game"
require_relative "game_control"


def init_game
  g = Game.new(File.dirname(__FILE__))
  g.log_to_console = true

  g.add_player("vitek",1)
  g.add_player("fedor(b)",1)

  g.start
  g
end

def  test_make_step_on_manual_mode
  g = init_game
  g.is_manual_roll_mode = true
  g.players[0].isbot = false
  g.players[0].name = 'kilk'
  g.curr.manual_roll = 3
  g.check_roll_and_make_step
  p g.logs
end
#test_make_step_on_manual_mode

def  test_auction
  g = init_game
  PlayerStep.make_step_roll(g,2,3)
  g.to_auction
  AuctionManager.run_action_job(g,"n")
end

def  test_random
  g = init_game
  g.curr.pos = 2
  pl = g.curr
  p "before: #{pl.money}"

  PlayerStep.process_position(g)
  #random = g.map.take_random_card()
  p g.logs
  p "after: #{pl.money}"

end
test_random


def  test_police_exit
  g = init_game
  pl = g.curr
  pl.pos = 10
  pl.police = 1
  pl.money=10000

  #pl.player_steps += [22,33,0,44]
  #p PlayerStep.check_on_tripple(pl.player_steps)


  [21,23,24].each_with_index do |id, ind|
    c = g.cells[id]
    c.owner = 1
  end
  mypid =0
  g.map.update_map

  g.check_roll_and_make_step
  p g.round_message

end
#test_police_exit


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

#test_build_houses

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
  g.players[1].isbot = false
  g.curr.pos = 5

  [9,13].each do |c|
    g.cells[c].owner = 0
  end
  [6,14].each do |c|
    g.cells[c].owner = 1
  end

  g.map.update_map

  PlayerStep.make_step(g)

  text = "#{g.curr_trade.from.name} надеется сделать обмен с #{g.curr_trade.to.name}, предлагает #{g.curr_trade.give_cells.map { |c| g.cells[c].name  }}"+
    " мечтает #{g.curr_trade.get_cells.map { |c| g.cells[c].name  }}"

  p text


  true ? TradeManager.complete_trade(g) : TradeManager.add_to_rejected_trades(g)

  p g.rejected_trades

end
#test_trade

#p BotBrainTrade.get_valid_trades(g,p)
#BotBrainTrade.try_do_trade(g)

def parse_trade_cmd
  g= init_game

  my_pid = '0'
  cmd = 'p0-6-8-9;p1-11-13;p2-23'

  data = cmd.split(';')
  from = data.find { |ss| ss.start_with?('p'+my_pid)  }
  to = data.select { |ss| !ss.start_with?('p'+my_pid)}.sort_by{|ss| -ss.size}.first
  return if to.nil?

  to_pid = to.split('-').first.sub('p','')
  give = from.sub("p#{my_pid}-",'').split('-').map { |e| g.cells[e.to_i]  }
  get = to.sub("p#{to_pid}-",'').split('-').map { |e| g.cells[e.to_i]  }

  ntr = Trade.new
  ntr.from = g.find_player(my_pid.to_i)
  ntr.give_cells = give
  #ntr.give_money = trule.give_money

  ntr.to = g.find_player(to_pid.to_i)
  ntr.get_cells = get
  #ntr.get_money = trule.get_money

  p ntr
end
#parse_trade_cmd
