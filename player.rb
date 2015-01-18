require_relative  'cell'

class PlayerManager
    attr_accessor  :g
    def initialize(g)
      @g = g
    end

    def step
      r0,r1 = g.last_roll[0],g.last_roll[1]
      pl = g.curr
      pl.pos += r0+r1
      pl.player_steps << r0*10+r1

      if check_on_tripple then
          pl.pos =10
          pl.police=1
          @player_steps.clear
          return false
      end
      if pl.pos>=40 then
          pl.money +=2000
          pl.pos-=40
      end
    end

    def check_on_tripple
      false
    end

    def self.pay(g, finish = true)
      p = g.curr
      amount = g.pay_amount
      ok = p.isbot ? BotBrainCells.mortgage_sell(g,p,amount) : p.money >= amount
      if ok
          p.money-=amount

          if g.pay_to_user
            g.find_player(g.pay_to_user).money += amount
            g.pay_to_user = nil
          end
          if finish
            g.finish_step("paid_"+ amount.to_s)
          else
            g.state = :BeginStep
          end

          g.pay_amount = 0
          return true
      else
          g.log "not enough money"
          g.to_cant_pay
      end

      g.logd "pl_act.end.pay"
      return false
    end

    def self.buy(g)
      return false if g.state != :CanBuy

      p = g.curr
      cell = g.curr_cell

      if cell.land? && cell.owner.nil?
          if p.isbot
            ff = BotActionsWhenBuy.factor_of_buy(g,p,cell)
            needbuy = ff >= 1

            if ff==1 and p.money < cell.cost
                needbuy = false
            elsif ff > 1 and p.money < cell.cost
                needbuy = BotBrainCells.mortgage_sell(g,p,cell.cost)
            end

            if needbuy
                g.map.set_owner(p,cell)
                g.finish_step("bought_#{cell.id}_f#{ff}")
            else
                g.to_auction
            end

          else
            if p.money < cell.cost
                g.state = :CantPay
                return
            else
                g.map.set_owner(p,cell)
                g.finish_step("bought_#{cell.id}")
            end
          end

      end
      g.logd "pl_act.end.buy"
    end

    def self.mortgage_cells(g, p, cells)
      text=""

      cells.each do |cid|
          cell = g.cells[cid]
          next if cell.mortg? or cell.houses_count>0
          p.money += cell.mortgage_amount
          cell.ismortgage = true
          text+="_#{cell.id}"
      end
      text

    end

    def self.unmortgage_cells(g, p, cells)
      text=""

      cells.each do |cid|
          cell = g.cells[cid]
          next if cell.active?
          p.money -= cell.unmortgage_amount
          cell.ismortgage = false
          text+="_#{cell.id}"
      end
      text
    end
    def self.build_houses(g, p, cells)
      text=""

      cells.each do |cid|
          cell = g.cells[cid]
          next if cell.houses_count>4 or !cell.monopoly?
          cell.houses_count+=1
          p.money -= cell.house_cost
          text+="_#{cell.id}"
      end
      text
    end

    def self.sell_houses(g, p, cells)
      text=""

      cells.each do |cid|
          cell = g.cells[cid]
          if cell.houses_count > 0
            cell.houses_count-=1
            p.money += cell.house_cost_when_sell
            text+="_#{cell.id}"
          end
      end
      text
    end
end

class Player
    attr_accessor :id, :name, :status, :isbot, :deleted, :money
    attr_accessor :pos, :last_roll, :man_roll, :isdouble_roll, :police_key
    attr_accessor :player_steps
    def initialize(id, name, isbot, money=15000)
      @player_steps = []
      @pos=0
      @id = id
      @name = name
      @isbot = isbot == 1
      @money = money
      @police_key =0
    end

    def hum?
      !@isbot
    end
    def bot?
      @isbot
    end
end