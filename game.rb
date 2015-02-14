require_relative  'game_manager'
require_relative  "cell"
require_relative  "utils"
require_relative  'map'
require_relative  'player'
require_relative  'player_steps'
require 'securerandom'

class Game

    attr_accessor :id, :state, :round, :last_roll
    attr_accessor  :map, :player, :cells, :player_cell_groups, :players, :selected, :winner
    attr_accessor :pay_amount, :pay_to_user
    attr_accessor :last_rcard, :community_chest, :chance_chest
    attr_accessor :curr_trade, :bot_trules, :rejected_trades,:completed_trades
    attr_accessor :curr_auction, :bot_arules

    attr_accessor :debug, :logs, :xlogs, :round_actions, :log_to_console, :log_game_rounds
    attr_accessor :manual_roll_mode, :update_interval, :manual_update
    attr_accessor :lang, :mtext, :round_message
    attr_accessor :ui_show_ok_when_endround

    def initialize(root_path="", lang="ru")
      @id = SecureRandom.hex(10)
      @lang = lang

      @players = []
      @cells = FileUtil.init_cells_from_file(root_path + "/data/lands_#{lang}.txt")
      @bot_trules = FileUtil.init_trades_from_file(root_path + "/data/trade_rules.txt")
      @bot_arules = FileUtil.init_aucrules_from_file(root_path + "/data/auc_rules.txt")
      FileUtil.init_chest_cards_from_file(self, root_path + "/data/chest_cards_#{lang}.txt")
      FileUtil.init_game_messages(self)

      @map = Map.new(self)
      @player = PlayerManager.new(self)
      @player_cell_groups = []

      @debug = false
      @rejected_trades = []
      @completed_trades =[]
      @logs =[]
      @xlogs =[]
      @log_to_console = false
      @log_game_rounds = false
      @update_interval = 1
      @manual_update = true
      @round_actions = []
      @ui_show_ok_when_endround = true

    end

    def start
      @selected = 0
      @players.size.times {|e| @player_cell_groups <<Array.new(11, 0)}

      to_begin
      @round = 1

      GameManager.every_n_seconds(@update_interval, self.finished?) do
          return if @round>300
          return if finished?

          #info if begin?
          GameManager.update_game(self)

      end if not @manual_update
    end
    def check_game
      @players.each do |pl|
          gr_counts = @player_cell_groups[pl.id]
          @player_cell_groups[pl.id]= Array.new(11, 0) if gr_counts.nil?
      end
    end

    def add_players(count, money=15000)
      @players << Player.new(0, "bot1", 1, money)
      @players << Player.new(1, "bot2", 1, money) if count >1
      @players << Player.new(2, "bot3", 1, money) if count >2

    end

    def curr
      @selected < @players.size ? @players[selected] : @players[0]
    end

    def curr_cell; cells[curr.pos] end


    def finish_step(act)
      fix_action(act) if !act.empty?

      #return if state == :EndStep

      @state = :EndStep
      if @manual_update &&  (curr.bot? || !@ui_show_ok_when_endround)
          finish_round()
      end
    end

    def finish_round()

      return if state != :EndStep

      GameManager.bot_actions_when_finish_step(self) if curr.isbot && @manual_update

      log_game_round if @log_game_rounds

      log "round_finished"

      @round+=1

      @selected = @selected < @players.size ?  (@selected+1) % @players.size : 0

      to_begin
      if curr.isbot && @manual_update
          #sleep(@update_interval)
          PlayerStep.make_step(self)
      end

    end

    def finished? ; @state == :FinishGame end


    def find_player(pid) @players.detect{|p| p.id == pid} end
    def find_player_by(user_name) @players.detect{|p| p.name == user_name} end

    def fix_action(act)
      log act
      logx act
    end

    def get_text(key)

      ind = lang_en? ? 0 : 1
      mtext.has_key?(key) ? mtext[key][ind] : key
    end

    def in_begin? ; @state == :BeginStep end

    def in_trade? ; @state == :Trade end

    def in_auction? ; @state == :Auction end

    def lang_en? ; @lang == "en" end

    def log_game_round
      @round_actions<<
      {
          round: @round,
          players_pos: @players.map{|p| p.pos}.to_a,
          cells:  @cells.map { |cc| cc.dup}
      }
    end

    def log(text)
      arr =text.split(' ')
      arr[0] = get_text(arr[0])
      ttext = arr.join(' ')
      logs << "[#{@round}] #{ttext}"
    end

    def logx(text)
      xlogs<<"[#{@round}] #{text}"
    end

    def logp(text)
      ttext = transl_text(text)
      ftext = "[#{curr.name}, #{curr.money},#{curr.pos}] #{ttext}"
      logs << "[#{@round}] #{ftext}"
    end

    def logd(text)
      puts "[debug] #{text}" if @debug
    end

    def move_to_cell
      if curr.isbot
          PlayerStep.move_after_random(self)
      else
          @state = :MoveToCell
      end
    end

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
    def player_trules(pid)
      @bot_trules

    end

    def set_state(state)
      @state = state if !finished?
    end

    def state_endround? ; @state == :EndStep end

    def to_begin; @state = :BeginStep end

    def to_random_cell
      if curr.isbot
          finish_step("") #_random_finished
      else
          @state = :RandomCell
      end
    end


    def to_pay(amount, finish = true)
      @pay_amount = amount;
      to_payam()
    end

    def to_payam(finish = true)
      @state = :NeedPay
      if curr.isbot && @manual_update  then  PlayerManager.pay(self, finish) end
    end

    def to_auction
      @state = :Auction
      AuctionManager.init_auction(self)
      AuctionManager.run_action_job(self, '') if curr.isbot && @manual_update
    end

    def to_cant_pay
      GameManager.check_payment if curr.isbot && @manual_update
    end

    def to_can_buy(finish = true)
      @state = :CanBuy
      if curr.isbot && @manual_update ;  PlayerManager.buy(self) end
    end


    def transl_text(text)
      arr = text.split(' ').map { |e| get_text(e) }.join(' ')
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
