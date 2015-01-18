require_relative "utils"
require_relative "map_printer"
require_relative "game"
require_relative "game_manager"
require_relative "player"
require_relative "game_control"


puts "---t2.rb"


g = Game.new(File.dirname(__FILE__))
g.players << Player.new(0, "kolyan", 0 , 15000)
g.players << Player.new(1, "bot1", 1 , 15000)

g.debug = false
g.update_interval  = 0.1

Thread.new {
    g.start
}
pr = MapPrinter.new

s="start"

loop do
    GameUI.info(g).each { |e| puts e  }

    pr.draw(g)

    text =  GameUI.show_game_state(g)

    p "#{g.curr.name} pos=#{g.curr.pos} #{text}"
    s = gets
    break if s.strip =="q"

    GameUI.process_command(g, s.strip)


end
