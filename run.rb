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

    g.debug = false
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
def test
    puts "---run console game.rb"

    g = Game.new(File.dirname(__FILE__))
    g.players << Player.new(0, "kilk", 0 , 15000)
    g.players << Player.new(1, "vovk", 0, 15000)

    g.debug = false
    g.auto_update = false
    g.start

    PlayerStep.make_step_roll(g,2,5)
    g.logs.map { |line| p line  }
    #g.cells.map { |e| p e.info  }

end
