require_relative  'cell'

class Player
  attr_accessor :id, :name, :status, :isbot, :deleted, :money
  attr_accessor :pos, :last_roll, :manual_roll, :police, :police_key
  attr_accessor :player_steps, :timer
  def initialize(id, name, isbot, money=15000)
    @player_steps = []
    @pos=0
    @id = id
    @name = name
    @isbot = isbot == 1
    @money = money
    @police =0
    @police_key =0
    @manual_roll =0
  end

  def hum?
    !@isbot
  end
  def bot?
    @isbot
  end
  def update_timer
    @timer = Time.now
  end
end


class PlayerManager
  attr_accessor  :g
  def initialize(g)
    @g = g
  end



  def self.pay(g, finish = true)
    p = g.curr
    p.update_timer
    amount = g.pay_amount
    ok = p.isbot ? BBCells.mortgage_sell(g,p,amount) : p.money >= amount
    if ok
      p.money-=amount
      if p.police>0
        p.police=0
        g.log "_paid_500_and_go_from_jail"
        PlayerStep.change_pos_and_process_position(g)
        return
      end

      if g.pay_to_user
        g.find_player(g.pay_to_user).money += amount
        g.pay_to_user = nil
      end

      if finish
        g.finish_step("_paid $#{amount}")
      else
        g.state = :BeginStep
      end

      g.pay_amount = 0
      return true
    else
      g.log "_not_enough_money"
      g.to_cant_pay
    end

    return false
  end

  def self.buy(g)
    return false if g.state != :CanBuy

    p = g.curr
    p.update_timer

    cell = g.curr_cell

    if cell.land? && cell.owner.nil?
      if p.isbot
        ff = BotActionsWhenBuy.factor_of_buy(g,p,cell)
        needbuy = ff >= 1

        if ff==1 and p.money < cell.cost
          needbuy = false
        elsif ff > 1 and p.money < cell.cost
          needbuy = BBCells.mortgage_sell(g,p,cell.cost)
        end

        if needbuy
          g.map.set_owner(p, cell, cell.cost)
          g.round_message += g.l "<br/>вы купили [#{cell.name}] за $#{cell.cost}","<br/>you purchased [#{cell.name}] for $#{cell.cost}"

          g.finish_step("_bought [#{cell.name}]")
        else
          g.to_auction
        end

      else
        if p.money < cell.cost
          g.state = :CanBuy
          g.logp  g.get_text("_not_enough_money")
          return
        else
          g.map.set_owner(p, cell, cell.cost)
          g.finish_step("_bought [#{cell.name}]")
          g.logx("bought_#{cell.id} f=#{ff}")
        end
      end

    end
  end

  def self.go_auc_bid(g, pl, cmd)
    pl.update_timer

    cell = g.curr_auction.cell
    fact = BotActionsWhenBuy.factor_of_buy(g, pl, cell)
    max_cost = cell.cost * fact

    max_money = g.player_assets(pl.id)
    needbid = pl.isbot ? (max_money >max_cost && g.curr_auction.curr_bid + 50 < max_cost) : cmd == "y" || cmd.empty?

  end

  def self.go_mortgage_cells(g, p, cells)
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

  def self.go_unmortgage_cells(g, p, cells)
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
  def self.go_build_houses(g, p, cells)
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

  def self.go_sell_houses(g, p, cells)
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
