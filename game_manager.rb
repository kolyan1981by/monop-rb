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
      when :BeginStep;    do_step(g)
      when :CanBuy;       PlayerManager.buy(g) if g.curr.isbot
      when :Auction;      AuctionManager.run_action_job(g, "auto")
      when :Trade;        TradeManager.run_trade_job(g)
      when :CantPay, :NeedPay; check_payment(g)
      when :EndStep;      bot_actions_when_finish_step(g)  if g.curr.isbot  ; g.finish_round
      else
          #puts g.state
      end
    end

    def self.do_step(g)
      if g.manual_mode
      else
          #g.logd "GameManager.do_step #{g.curr.id}"
          PlayerStep.make_step(g) if g.curr.isbot
      end
    end



    def self.check_payment(g)
      if g.curr.isbot
          leave_game(g) unless PlayerManager.pay(g)
      end
    end

    def self.bot_actions_before_roll(g)
      BotBrainTrade.try_do_trade(g)
    end

    def self.bot_actions_when_finish_step(g)

      BotBrainCells.unmortgage_cells(g);

      sum = 0.8*g.player_assets(g.curr.id, false)

      BBHouses.build_houses(g, sum);
    end

    def self.leave_game(g)
      p = g.curr
      pid = p.id

      if g.players.count >= 2
          g.players.delete(p)
          g.map.cells_by_user(pid).each{|c| c.owner = nil;c.houses_count=0}
          g.log g.get_text("player_left_game") % p.name
      end

      if g.players.count == 1
          g.winner = g.players.first
          g.state = :FinishGame
          g.log 'game_finished'
      end
    end


end
