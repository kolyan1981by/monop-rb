require_relative  "game"

module TradeManager
    def self.run_trade_job(g)
      trade = g.curr_trade

      complete_trade(g) if trade.from.isbot && trade.to.isbot

      make_trade_player2bot(g) if trade.from.hum? && trade.to.isbot

      if trade.to.hum?
          rejected = check_bot_tohuman_rejected_trades(g)
          g.to_begin if rejected
      end
    end

    def self.complete_trade(g)
      g.log  "make trade"
      g.completed_trades << g.curr_trade
      trade = g.curr_trade
      trade.give_cells.each{|c| g.cells[c].owner = trade.to.id }
      trade.get_cells.each{|c| g.cells[c].owner = trade.from.id}
      trade.from.money += trade.get_money-trade.give_money
      trade.to.money += trade.give_money-trade.get_money
      g.map.update_map
      g.fix_action("trade_completed_give[#{trade.give_cells.join('_')}]_get[#{trade.get_cells.join('_')}]")
      g.to_begin
    end

    def self.make_trade_player2bot(g)
      currtrade = g.curr_trade
      trs = BotBrainTrade.get_valid_trades(g,currtrade.to)

      if is_good_trade(currtrade, trs)
          complete_trade(g)
          g.fix_action("trade_completed")
          return true
      end
      g.to_begin
      return false
    end

    def self.is_good_trade(tr, trades)
      trades.each do |v|
          if v.to.id == tr.from.id
            if (equal_tr_cells(v.get_cells,tr.give_cells) &&
               tr.give_money >= v.give_money &&
               tr.get_money <= v.get_money)

                return true
            end
          end
      end
      return false
    end

    def self.equal_tr_cells(a,b)
      (a-b).empty? || (b-a).empty?
    end

    def self.add_to_rejected_trades(g)
      g.rejected_trades << g.curr_trade
      g.to_begin
    end

    def self.check_bot_tohuman_rejected_trades(g)
      g.rejected_trades.select{|r| r == g.curr_trade}.any?
    end

end
