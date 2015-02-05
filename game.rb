require_relative  'game_manager'
require_relative  "cell"
require_relative  "utils"
require_relative  'map'
require_relative  'player'
require_relative  'player_steps'
require 'securerandom'

class Game

    attr_accessor :id, :state, :round, :last_roll
    attr_accessor  :map, :player, :cells, :players, :pcount, :selected, :winner
    attr_accessor :pay_amount, :pay_to_user
    attr_accessor :last_rcard, :community_chest, :chance_chest
    attr_accessor :curr_trade, :bot_trules, :rejected_trades,:completed_trades
    attr_accessor :curr_auction, :bot_arules
    attr_accessor :debug, :manual_mode, :logs, :round_actions, :log_to_console, :log_game_rounds, :update_interval,:auto_update
    attr_accessor :lang, :mtext

    def initialize(root_path="", lang="ru")
      @id = SecureRandom.hex(10)
      @lang = lang

      @players = []
      @cells = FileUtil.init_cells_from_file(root_path + "/data/lands.txt")
      @bot_trules = FileUtil.init_trades_from_file(root_path + "/data/trade_rules.txt")
      @bot_arules = FileUtil.init_aucrules_from_file(root_path + "/data/auc_rules.txt")
      FileUtil.init_chest_cards_from_file(self, root_path + "/data/chest_cards_#{lang}.txt")
      FileUtil.init_game_messages(self)

      @map = Map.new(self)
      @player = PlayerManager.new(self)

      @debug = false
      @rejected_trades = []
      @completed_trades =[]
      @logs =[]
      @log_to_console = false
      @log_game_rounds = false
      @update_interval = 1
      @auto_update = true
      @round_actions = []

    end

    def add_players(count,money=15000)
      @players << Player.new(0, "bot1", 1, money)
      @players << Player.new(1, "bot2", 1, money) if count >1
      @players << Player.new(2, "bot3", 1, money) if count >2

    end

    def start
      @selected = 0
      @pcount = players.count
      to_begin
      @round = 1

      GameManager.every_n_seconds(@update_interval, self.finished?) do
          return if @round>300
          return if finished?

          #info if begin?
          GameManager.update_game(self)

      end if @auto_update


    end

    def player_trules(pid)
      @bot_trules

    end

    def curr
      @selected < @pcount ? @players[selected]
      :
          @pcount ==0 ? "finish": @players[0]

    end

    def find_player(pid) @players.detect{|p| p.id == pid} end

    def find_player_by(user_name) @players.detect{|p| p.name == user_name} end



    def player_assets(pid,inclMonop = true)
      sum=0
      cells.select{|c| c.owner==pid && c.active?}.each do |c|
          if inclMonop
            sum+=c.mortgage_amount
            sum+=c.houses_count*c.house_cost_when_sell if c.houses_count>0
          else
            sum+=c.mortgage_amount if !c.monopoly?
          end
      end
      sum + find_player(pid).money
    end

    def curr_cell; cells[curr.pos] end

    def finish_step(act)
      fix_action(act) if !act.empty?

      #return if state == :EndStep

      @state = :EndStep

      finish_round() if !@auto_update
    end

    def finish_round()

      return if state != :EndStep
      GameManager.bot_actions_when_finish_step(self) if curr.isbot && !@auto_update

      log_game_round if @log_game_rounds

      log "round [#{@round}] finished"
      log "---------------------"

      @round+=1

      @selected = @selected < @pcount ?  (@selected+1) % @pcount : 0

      to_begin

    end

    def fix_action(act)
      log act
    end

    def log_game_round
      @round_actions<<
      {
          round: @round,
          players_pos: @players.map{|p| p.pos}.to_a,
          cells:  @cells.map { |cc| cc.dup}
      }
    end

def set_state(state) if !finished? then @state = state end end

def begin? ; @state == :BeginStep end

def in_trade? ; @state == :Trade end

def in_auction? ; @state == :Auction end

def finished? ; @state == :FinishGame end

def to_begin; @state = :BeginStep end

def lang_en? ; @lang == "en" end

def get_text(key)
    lang_en? ? mtext[0] : mtext[1]
end

def to_random_cell
    if curr.isbot
      finish_step("")
    else
      @state = :RandomCell
    end
end

def move_to_cell
    if curr.isbot
      PlayerStep.move_to_cell(self)
    else
      @state = :MoveToCell
    end

end

def to_pay(amount, finish = true)
    @pay_amount = amount;
    to_payam()
end

def to_payam(finish = true)
    @state = :NeedPay
    if curr.isbot && !@auto_update  then  PlayerManager.pay(self, finish) end
end

def to_auction
    @state = :Auction
    AuctionManager.init_auction(self)
end

def to_cant_pay
end

def to_can_buy(finish = true)
    @state = :CanBuy
    if curr.isbot && !@auto_update ;  PlayerManager.buy(self) end
end

def log(text)
    puts text if @log_to_console
    logs<<"[#{@round}] #{text}"
end

def logp(text)
    ftext = "[#{curr.name}, #{curr.money}] #{text}"
    puts ftext if @log_to_console

    logs << "[#{@round}] #{ftext}"
end

def logd(text)
    puts "[debug] #{text}" if @debug
end



end


class Trade
    attr_accessor :id,:reversed, :from, :to, :give_cells, :get_cells,:give_money, :get_money
    def ==(an)
      pls = @from.id == an.from.id && @to.id == an.to.id
      lands1 = @give_cells & an.give_cells == @give_cells
      lands2 = @get_cells & an.get_cells == @get_cells
      money = @get_money == an.get_money && @give_money == an.give_money
      pls && lands1 && lands2 && money
    end

end

class TRule
    attr_accessor :id, :disabled
    attr_accessor :my_count,:get_land,:get_count,:get_money
    attr_accessor :your_count,:give_land,:give_count,:give_money
    attr_accessor :money_factor
end

class Auction
    attr_accessor :cell, :curr_bid, :curr_pl, :last_bidded_player, :finished, :auc_pls
    def next_bid
      @curr_bid += 50
    end
end

class ARule
    attr_accessor :id, :disabled
    attr_accessor :group_id,:my_count,:an_count,:need_build_houses,:groups_with_houses
    attr_accessor :my_money,:factor
end

class ChestCard

    attr_accessor :type, :random_group, :text, :money, :pos
    def initialize(params = {})
      @type = params.fetch(:type, 6)
      @random_group = params.fetch(:random_group, 1)
      @text = params.fetch(:text, 'random card')
      @money = params.fetch(:money, 0)
      @pos = params.fetch(:pos, 0)
    end

end
