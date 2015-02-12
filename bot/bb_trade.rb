class BotBrainTrade
    def self.try_do_trade(g)

      trs = get_valid_trades(g,g.curr)

      found = nil
      trs.each do |tr|
          res = g.rejected_trades.any?{|x| x==tr}
          if !res
            found = tr
            break
          end
      end

      if !found.nil?
          g.curr_trade = found
          g.state = :Trade
          return true
      end

      return false
    end

    def self.get_valid_trades(g,pl)
      res = []

      g.player_trules(pl.id).each do |rule|
          tr  = checkon_players_cells(g, rule, pl.id)
          if tr.nil?
            tr  = checkon_players_cells(g,reverse_rule(rule),pl.id)
            tr.reversed = true if !tr.nil?
          end

          if !tr.nil? ;  res<<tr end

      end
      res
    end

    def self.checkon_players_cells(g, trule, my)

      my_pl = g.find_player(my)
      groups = g.player_cell_groups

      groups.each_with_index do |anpl_groups, an_pid|

          next if an_pid == my
          next if anpl_groups[trule.get_land] != trule.get_count


          an_p = g.find_player(an_pid)

          #i have
          my_count = groups[my][trule.get_land] == trule.my_count
          #you have
          your_count = groups[an_pid][trule.give_land] == trule.your_count

          #i give to you
          giveCells = g.map.cells_by_user_by_group(my, trule.give_land)
          #money factor
          money1 = g.player_assets(my, false)
          money2 = g.player_assets(an_pid, false)

          #p "money_factor NIL" if trule.money_factor.nil?

          mfac = (money1.to_f / money2) >= trule.money_factor

          if giveCells.size == trule.give_count && my_count && your_count && mfac
            ntr = Trade.new
            ntr.from = my_pl
            ntr.give_cells = giveCells.map(&:id)
            ntr.give_money = trule.give_money
            ntr.to = an_p
            ntr.get_cells = g.map.cells_by_user_by_group(an_pid,trule.get_land).map(&:id)
            ntr.get_money = trule.get_money
            ntr.id = trule.id

            return ntr
          end

      end

      return nil
    end

    def self.reverse_rule(trule)
      revs = TRule.new

      revs.id = trule.id
      revs.my_count = trule.your_count
      revs.your_count = trule.my_count

      revs.get_count = trule.give_count
      revs.get_land = trule.give_land
      revs.get_money = trule.give_money

      revs.give_count = trule.get_count
      revs.give_land = trule.get_land
      revs.give_money = trule.get_money

      revs.money_factor = 1.0/trule.money_factor

      return revs

    end
end
