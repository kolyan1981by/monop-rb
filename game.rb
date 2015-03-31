require_relative  'game_manager'
require_relative  "cell"
require_relative  "utils"
require_relative  'map'
require_relative  'player'
require_relative  'player_steps'
require 'securerandom'

class Game

  attr_accessor :id, :state, :round, :last_roll, :manual_roll, :round_time
  attr_accessor  :map, :player, :cells, :player_cell_groups, :players, :selected, :winner
  attr_accessor :pay_amount, :pay_to_user
  attr_accessor :last_rcard, :community_chest, :chance_chest
  attr_accessor :curr_trade, :bot_trules, :rejected_trades,:completed_trades
  attr_accessor :curr_auction, :bot_arules

  attr_accessor :debug, :logs, :xlogs, :round_actions,:isconsole, :log_to_console, :log_game_rounds
  attr_accessor :is_manual_roll_mode, :update_interval, :manual_update
  attr_accessor :lang, :mtext, :round_message
  attr_accessor :ui_show_ok_when_endround

  def initialize(root_path="", lang="ru")
    @id = SecureRandom.hex(10)
    @lang = lang

    @players = []
    @cells = FileUtil.init_cells_from_file(File.join(root_path,"/data/lands_#{lang}.txt"))
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
    @xlogs =[]
    @log_to_console = false
    @log_game_rounds = false
    @update_interval = 1
    @round_actions = []
    @round_message = ''
    @ui_show_ok_when_endround = true
    @isconsole = false
    @player_cell_groups = []
    @player_cell_groups = Array.new(4) { Array.new(11, 0) }

  end

  def start
    @selected = 0
    to_begin
    @round = 1
    @round_time=Time.now

    GameManager.every_n_seconds(@update_interval, self.finished?) do
      return if @round>300
      return if finished?

      #info if begin?
      GameManager.update_game(self)

    end if false
  end

  def add_player(uname, isbot=1)
    @players << Player.new(@players.size, uname, isbot, 15000)
  end

  def check_roll_and_make_step
    need_roll = true
    if is_manual_roll_mode
      need_roll = players.all? { |pl|  pl.hum? ? pl.manual_roll !=0 : true }
    end
    PlayerStep.make_step(self) if need_roll

  end

  def curr
    @selected < @players.size ? @players[selected] : @players[0]
  end
  def curr?(uname)
    curr.name == uname
  end
  def curr_cell; cells[curr.pos] end


  def finish_step(act)
    fix_action(act) if !act.empty?

    @state = :EndStep

    if curr.hum? && !@ui_show_ok_when_endround
      finish_round
    end
  end

  def finish_round

    return if state != :EndStep

    GameManager.bot_actions_when_finish_step(self) if curr.isbot

    log_game_round if @log_game_rounds

    log "_round_finished"

    if is_manual_roll_mode
      players.each{|pl| pl.manual_roll =0}
    end

    @round+=1
    last_roll = curr.player_steps.last

    if not [11,22,33,44,55,66].include? last_roll
      @selected = @selected < @players.size ?  (@selected+1) % @players.size : 0
    end

    to_begin
    curr.update_timer

    if  curr.isbot #&& !@ui_show_ok_when_endround
      #sleep(@update_interval)
      check_roll_and_make_step
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

  def in_end_round? ; @state == :EndStep end

  def lang_en? ; @lang == "en" end

  def l(text_ru,text_en)
    lang_en? ? text_en : text_ru
  end

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
    xlogs "[debug] #{text}" if @debug
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
    PlayerManager.pay(self, finish) if curr.bot?
  end

  def to_auction
    @state = :Auction
    AuctionManager.init_auction(self)
    AuctionManager.run_action_job(self, '') if curr.bot?
  end

  def to_cant_pay
    GameManager.check_payment(self) if curr.bot?
  end

  def to_can_buy(finish = true)
    @state = :CanBuy
    PlayerManager.buy(self) if curr.bot?
  end
  def to_trade
    @state = :Trade
    TradeManager.run_trade_job(self)
  end

  def transl_text(text)
    arr = text.split(' ').map { |e| get_text(e) }.join(' ')
  end


  def get_round_timer
    (Time.now - curr.timer).round unless curr.timer.nil?
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
