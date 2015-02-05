require_relative "utils"
require_relative "game"
require_relative "game_manager"
require_relative "player"
require_relative "player_steps"

module  GameUI
    def self.help_info
      p "to mortgage cells , enter m-1-4 ... , where -1-4 ids of cells"
      p "to unmortgage cells , enter um-1-4 ..., where -1-4 ids of cells"
      p "to build houses, enter bh-1-4 ..., where -1-4 ids of cells"
      p "to sell houses, enter sh-1-4 ..., where -1-4 ids of cells"

    end

    def self.show_game_state(g)
      case g.state
      when :BeginStep;     "begin step"
      when :CanBuy;        "you can buy cell #{g.curr_cell.id} or auction [your money #{g.curr.money}], enter b/a:" if g.curr.hum?
      when :Auction;       "do you want bid? [y n]" #if g.curr_auction.curr_pl.hum?
      when :Trade;         "player #{g.curr_trade.from.id} wants trade  give=#{g.curr_trade.give_cells} get#{g.curr_trade.get_cells}, enter y/n"
      when :CantPay;       "you need mortgage cells to find money"
      when :NeedPay;       "yoy need pay, press enter" if g.curr.hum?
      when :RandomCell;    "#{g.last_rcard.text}, press enter" if g.curr.hum?
      when :MoveToCell;    "move to cell" if g.curr.hum?
      when :EndStep;
      else
          g.state
      end
    end
    def self.show_game_state_ru(g)
      case g.state
      when :BeginStep;     "начало хода"
      when :CanBuy;        "вы можете купить #{g.curr_cell.id} или выставить на аукцион, жми b/a:" if g.curr.hum?
      when :Auction;       "увеличить ставку? [y n]" #if g.curr_auction.curr_pl.hum?
      when :Trade;         "игрок #{g.curr_trade.from.id} хочет обменяться, дает #{g.curr_trade.give_cells} хочет #{g.curr_trade.get_cells}, жми y/n"
      when :CantPay;       "заложите или что-нибудь продайте, чтобы заплатить"
      when :NeedPay;       "нужно заплатить, жми enter" if g.curr.hum?
      when :RandomCell;    "#{g.last_rcard.text}, жми enter" if g.curr.hum?
      when :MoveToCell;    "предлагают проехаться на клетку" if g.curr.hum?
      when :EndStep;
      else
          g.state
      end
    end
    def self.process_command(g, cmd)
      #puts "#{g.state} process_command: #{cmd}"
      #GameManager.update_game(g) if g.curr.isbot

      case g.state
      when :BeginStep;
          help_info if cmd=='h'
          PlayerStep.make_step(g) if cmd.empty?

          PlayerStep.make_step(g, cmd.sub('r','').to_i) if cmd.start_with?('r')

          mortgage(g, cmd) if cmd.start_with?('m');

          unmortgage(g, cmd) if cmd.start_with?('um')

      when :CanBuy;       if cmd != "a" then PlayerManager.buy(g) else g.to_auction end
      when :Auction;      AuctionManager.run_action_job(g,cmd)
      when :Trade;        cmd == "y" ? TradeManager.complete_trade(g) : TradeManager.add_to_rejected_trades(g)
      when :CantPay, :NeedPay;      get_money(g, cmd); PlayerManager.pay(g)
      when :RandomCell;   g.finish_step("random_finished")
      when :MoveToCell;   PlayerStep.move_after_random(g)
      when :EndStep;      g.finish_round ; puts ""
      else
          puts g.state
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
      PlayerManager.mortgage_cells(g, g.curr, cells)
    end
    def self.unmortgage(g,cmd)
      cmd['um']='' if cmd.start_with?('um')
      cells =cmd.split('-').map{ |cc| cc.to_i  }
      PlayerManager.unmortgage_cells(g, g.curr, cells)
    end


    def self.info(g)
      res=[]
      #log "#{g.round}: #{g.curr.name}"

      g.players.each do |p|
          cells = g.map.cells_by_user(p.id)
          active = cells.select{|c| c.active? && c.houses_count == 0}.map(&:id)
          mortg = cells.select{|c| c.mortg?}.map(&:id)
          housed = cells.select{|c| c.houses_count > 0}.map(&:id)

          cells_info = "cells #{active} mortg #{mortg} with houses #{housed}"

          #res<< "#{p.name},#{p.money} #{cells_info}"
          res<< "#{p.name} #{p.money}"
      end

      res
    end

    def self.show_last_round(g)
      r = g.round
      #logs = g.logs.select{ |l| l.start_with?("[#{r}]") or l.start_with?("[#{r-1}]") }
      logs = g.logs.select{ |l| l.start_with?("[#{r}]") }
      logs.each { |e| p e }
    end
end
