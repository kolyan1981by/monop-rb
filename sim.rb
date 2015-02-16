
require_relative "game"


module Sim
    def self.run
        puts "---run game simulator"

        g = Game.new(File.dirname(__FILE__))

        g.update_interval =0.01
        #g.log_to_console =false
        g.manual_update = false

        g.add_players(2)
        g.start

        path = '/tmp/monop.log'

        File.open(path, 'w') do |file|
            g.xlogs.each{|l| file.puts l }
        end
        puts "finished"
        system "mousepad "+ path
    end
end
#Sim.run
