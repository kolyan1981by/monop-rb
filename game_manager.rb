require_relative  "game"
require_relative  "auc_manager"
require_relative  "trade_manager"
module GameManager


  def self.every_n_seconds(n,finished)
    loop do
      before = Time.now
      yield
      interval = n-(Time.now-before)
      sleep(interval) if interval > 0
    end
  end

  def self.update_game(g)

    case g.state
    when :BeginStep;    g.check_roll_and_make_step
    when :CanBuy;       PlayerManager.buy(g) if g.curr.isbot
    when :Auction;      AuctionManager.run_action_job(g, "auto")
    when :Trade;        TradeManager.run_trade_job(g)
    when :CantPay, :NeedPay; check_payment(g)
    when :EndStep;      bot_actions_when_finish_step(g)  if g.curr.isbot  ; g.finish_round
    else
      #puts g.state
    end
  end




  def self.check_payment(g)
    if g.curr.isbot
      leave_game(g) #if not PlayerManager.pay(g)
    end
  end

  def self.bot_actions_before_roll(g)
    if BotBrainTrade.try_do_trade(g)
      TradeManager.run_trade_job(g)
    end
  end

  def self.bot_actions_when_finish_step(g)

    BBCells.unmortgage_cells(g);

    sum = 0.8*g.player_assets(g.curr.id, false)

    BBHouses.build_houses(g, sum);
  end

  def self.leave_game(g)
    p = g.curr

    if g.players.count >= 2
      g.players.delete(p)

      #set owner <= nil
      g.map.cells_by_user(p.id).each{|c| c.owner = nil; c.houses_count=0}

      #zero cell groups count
      g.player_cell_groups[p.id] = Array.new(11, 0)
      g.log g.get_text("_player_left_game") % p.name
    end

    if g.players.count == 1
      g.winner = g.players.first
      g.state = :FinishGame
      g.log '_game_finished'
    end
  end


end
