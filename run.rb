require_relative "utils"
require_relative "map_printer"
require_relative "game"
require_relative "game_manager"
require_relative "player"
require_relative "game_control"

def run_console_game
    puts "---run console game.rb"


    g = Game.new(File.dirname(__FILE__))
    g.players << Player.new(0, "kilk", 0 , 15000)
    g.players << Player.new(1, "vovk", 0 , 15000)

    g.update_interval  = 0.1

    Thread.new { g.start }

    sleep(1)
    pr = MapPrinter.new

    s="start"

    loop do
      #GameUI.info(g).each { |e| puts e  }

      #pr.draw(g)

      text =  GameUI.show_game_state_ru(g)

      p "#{g.state}:#{g.curr.name}:#{g.curr.pos} #{text}" if g.state != :EndStep
      s = gets
      break if s.strip =="q"

      GameUI.process_command(g, s.strip)
      p g.logs.last #GameUI.show_last_round(g)

    end
end

#run_console_game
def initg
    puts "---run console game.rb"

    g = Game.new(File.dirname(__FILE__))
    g.players << Player.new(0, "kilk", 1 , 15000)
    g.players << Player.new(1, "vovk", 1, 15000)

    g.manual_update = true
    g.ui_show_ok_when_endround = false

    g.start
    g
end

def test_auc
    g = initg
    PlayerStep.make_step_roll(g,2,3)
    g.to_auction
    AuctionManager.run_action_job(g,"n")
end

def test_upd_map
    g = initg

    g.cells[6].owner=1
    #g.cells[8].owner=1
    g.cells[9].owner=0
    #g.cells[11].owner=0
    g.cells[13].owner=0
    g.cells[14].owner=1

    g.map.update_map
    #p g.player_cell_groups
    PlayerStep.make_step(g)
end
#test_upd_map
