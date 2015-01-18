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
      #g.log "Exchange between #{found.from.id} and #{found.to.id} give=#{found.give_cells} get=#{found.get_cells}"
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

      res << tr if !tr.nil?
    end
    res
  end

  def self.checkon_players_cells(g, trule, my)

    pfrom = g.find_player(my)

    wantedCellsGroupedByUser = g.map.cells_by_group(trule.get_land)
    .select{|x| !x.owner.nil? && x.owner != my}.group_by(&:owner)

    if !wantedCellsGroupedByUser.any? then return nil end

    wantedCellsGroupedByUser.each do |wantedByUser|
      next if wantedByUser[1].length != trule.get_count

      pto = g.find_player(wantedByUser[0])

      #i have
      _myCells = g.map.cells_by_user_by_group(my, trule.get_land).length == trule.my_count
      #you have
      _yourCells = g.map.cells_by_user_by_group(pto.id, trule.give_land).length == trule.your_count
      #i give to you
      giveCells = g.map.cells_by_user_by_group(my, trule.give_land)
      #money factor
      money1 = g.player_assets(my, false)
      money2 = g.player_assets(pto.id, false)

      p "money_factor NIL" if trule.money_factor.nil?

      mfac = (money1.to_f / money2) >= trule.money_factor

      if giveCells.length == trule.give_count && _myCells && _yourCells && mfac
        ntr = Trade.new
        ntr.from = pfrom
        ntr.give_cells = giveCells.map{|c| c.id}
        ntr.give_money = trule.give_money
        ntr.to = pto
        ntr.get_cells = wantedByUser[1].map(&:id)
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