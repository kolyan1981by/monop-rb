require_relative "utils"
require_relative "game"
require_relative  'game_manager'
require_relative "player"
require_relative "player_steps"


puts "---t1.rb"

g = Game.new(File.dirname(__FILE__))
g.update_interval =0.01
g.debug =false
g.log_to_console =false

g.add_players(2)
g.start

path = '/tmp/monop.log'

File.open(path, 'w') do |file|
    g.logs.each{|l| file.puts l }
end
puts "finished"
system "mousepad "+ path
