require_relative "game"

module  GameUI
  def self.help_info
    p "to mortgage cells , enter m-1-4 ... , where -1-4 ids of cells"
    p "to unmortgage cells , enter um-1-4 ..., where -1-4 ids of cells"
    p "to build houses, enter bh-1-4 ..., where -1-4 ids of cells"
    p "to sell houses, enter sh-1-4 ..., where -1-4 ids of cells"

  end


  def self.show_game_state_en(g, uname)
    case g.state
    when :BeginStep;     "start round,  #{ g.is_manual_roll_mode ? 'choose one number [1..6]' : 'write [game roll]'}"
    when :CanBuy;        "you can buy [#{g.curr_cell.name}] or auction, write [game b] or [game a]" if g.curr.hum?
    when :Auction;       "do you want bid? [y n]" #if g.curr_auction.curr_pl.hum?
    when :Trade;         "player #{g.curr_trade.from.id} wants trade, give #{g.curr_trade.give_cells} wants #{g.curr_trade.get_cells}, write [game y] or [game n]"
    when :CantPay;       "you need mortgage cells to find money"
    when :NeedPay;       "yoy need pay, write [game pay]" if g.curr.hum?
    when :RandomCell;    # "#{g.logs.last}, write [game go]" if g.curr.hum?
    when :MoveToCell;    # "#{g.logs.last}" if g.curr.hum?
    when :EndStep;       "#{g.round_message.gsub('<br/>',', ')}"
    else
      g.state
    end
  end
  def self.show_game_state_ru(g, uname)
    case g.state
    when :BeginStep;     "начало хода,  #{ g.is_manual_roll_mode ? 'выберите кубик от 1 до 6 для соперника' : 'нажмите кнопку'}"
    when :CanBuy;        "вы можете купить #{g.curr_cell.id} или выставить на аукцион, жми b/a:" if g.curr.hum?
    when :Auction;       "увеличить ставку? [y n]" #if g.curr_auction.curr_pl.hum?
    when :Trade;         "игрок #{g.curr_trade.from.id} хочет обменяться, дает #{g.curr_trade.give_cells} хочет #{g.curr_trade.get_cells}, жми y/n"
    when :CantPay;       "заложите или что-нибудь продайте, чтобы заплатить"
    when :NeedPay;       "нужно заплатить, жми enter" if g.curr.hum?
    when :RandomCell;    "#{g.logs.last}, жми enter" if g.curr.hum?
    when :MoveToCell;    "#{g.logs.last}" if g.curr.hum?
    when :EndStep;       "#{g.round_message.gsub('<br/>',', ')}"
    else
      g.state
    end
  end
  def self.process_command(g, cmd, uname)
    #puts "#{g.state} process_command: #{cmd}"
    #GameManager.update_game(g) if g.curr.isbot

    cmd.sub!('game ','') if !cmd.nil? && cmd.start_with?('game ')

    case g.state
    when :BeginStep;
      help_info if cmd=='h'

      mortgage(g, cmd) if cmd.start_with?('m')

      unmortgage(g, cmd) if cmd.start_with?('um')

      if g.curr?(uname) && cmd.start_with?('pay')
        g.pay_amount = 500
        PlayerManager.pay(g, false)
        g.curr.police=0
        g.log g.l "вы заплатили $500 и выходите из тюрьмы", "you paid $500 and can roll"
        return
      end

      r0 = cmd.empty? ||  cmd =='r0' ? 0 : cmd.sub('r','').to_i

      if g.is_manual_roll_mode
        g.find_player_by(uname).manual_roll = r0
      end
      g.check_roll_and_make_step

    when :CanBuy;       cmd != "a" ? PlayerManager.buy(g) : g.to_auction
    when :Auction;      AuctionManager.run_action_job(g,cmd)
    when :Trade;
      cmd == "y" ? TradeManager.complete_trade(g) : TradeManager.add_to_rejected_trades(g)
      PlayerStep.make_step(g) if g.curr.isbot
    when :CantPay, :NeedPay;      get_money(g, cmd); PlayerManager.pay(g)
    when :RandomCell;   g.finish_step('')
    when :MoveToCell;   PlayerStep.move_after_random(g)
    when :EndStep;       g.finish_round
    else
      puts g.state
    end

  end

  def self.start_roll_when_police(g,cmd,uanme)
    if cmd.start_with?('pay')
      g.pay_amount = 500
      PlayerManager.pay(g, false)
      g.curr.police=0

    end
  end

  def self.get_money(g,cmd)
    if cmd.start_with?('m')
      cmd['m']=''
      cells =cmd.split('-').map{ |cc| cc.to_i  }
      PlayerManager.mortgage_cells(g, g.curr, cells)
    end

    if cmd.start_with?('sh')
      cmd['sh']=''
      cells =cmd.split('-').map{ |cc| cc.to_i  }
      PlayerManager.sell_houses(g, g.curr, cells)
    end

  end

  def self.mortgage(g,cmd)
    cmd['m']='' if cmd.start_with?('m')
    cells =cmd.split('-').map{ |cc| cc.to_i  }
    PlayerManager.go_mortgage_cells(g, g.curr, cells)
  end

  def self.unmortgage(g,cmd)
    cmd['um']='' if cmd.start_with?('um')
    cells =cmd.split('-').map{ |cc| cc.to_i  }
    PlayerManager.go_unmortgage_cells(g, g.curr, cells)
  end

  def self.player_houses_info(g)
    res=[]
    g.players.each do |p|
      cells = g.map.cells_by_user(p.id)
      active = cells.select{|c| c.active? && c.houses_count == 0}.map(&:id)
      mortg = cells.select{|c| c.mortg?}.map(&:id)
      housed = cells.select{|c| c.houses_count > 0}.map{|c| [c.id, c.houses_count]}
      cells_info = "cells #{active} mortg #{mortg} with houses #{housed}"
      res<< "#{p.name},#{p.money} #{cells_info}"
    end

    res
  end

  def self.show_last_round(g)
    r = g.round
    #logs = g.logs.select{ |l| l.start_with?("[#{r}]") or l.start_with?("[#{r-1}]") }
    logs = g.logs.select{ |l| l.start_with?("[#{r}]") }
    #logs.each { |e| p e }
  end

  def self.init_trade(g, cmd, uname)

    from = g.find_player_by(uname);
    return false if from.nil?

    data = cmd.split(';')

    from_cells = data.find { |ss| ss.start_with?("p#{from.id}")  }
    to_cells = data.select { |ss| not ss.start_with?("p#{from.id}")}.sort_by{|ss| -ss.size}.first
    return false if to_cells.nil?

    to_pid = to_cells.split('-').first.sub('p','')
    give = from_cells.sub("p#{from.id}-",'').split('-').map { |e| e.to_i  }
    get = to_cells.sub("p#{to_pid}-",'').split('-').map { |e| e.to_i  }

    ntr = Trade.new
    ntr.from = from
    ntr.give_cells = give
    #ntr.give_money = trule.give_money

    ntr.to = g.find_player(to_pid.to_i)
    ntr.get_cells = get
    #ntr.get_money = trule.get_money

    g.curr_trade = ntr
    g.to_trade
    return true

  end

end
