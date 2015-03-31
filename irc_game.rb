require 'cinch'
require 'redis'
require_relative "game"
require_relative "game_control"

def  init_console_game

  g = Game.new(File.dirname(__FILE__), "en")

  g.add_player("human",0)
  g.add_player("jon_bot",1)

  g.update_interval  = 0.1
  g.ui_show_ok_when_endround  = true
  g.isconsole = true

  g.start

  sleep(1)

  return g

end

g = init_console_game
my_name = 'human'

bot = Cinch::Bot.new do
  configure do |c|
    c.server = "irc.freenode.org"
    c.nick = "citipoly"
    c.channels = ["#citipoly"]
  end

  on :message, /^game (.+?)/ do |m, text|

    #m.reply g.round_message.gsub("<br/>",", ").gsub("<br />",", ")

    logs = g.logs.select{ |l| l.start_with?("[#{g.round}]") }
    logs_1 = g.logs.select{ |l| l.start_with?("[#{g.round-1}]") }

    #logs = logs_1 if logs.size ==0

    m.reply logs if !logs.empty?

    text =  GameUI.show_game_state_en(g,my_name)

    m.reply "#{text}" if g.state != :EndStep && text!=''

    GameUI.process_command(g, text, my_name)
  end

  on :message, /^!save/ do |m|
    redis = Redis.new
    redis.set("irc_game", g)
    m.reply "game saved"
  end
  on :message, /^!load/ do |m|
    redis = Redis.new
    g = redis.get("irc_game")
    m.reply "game loaded"
  end
  on :message, /^!new/ do |m|
    g = init_console_game
  end
end


bot.start
