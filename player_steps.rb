require_relative  "bot/bb_buy"
require_relative  "bot/bb_houses"
require_relative  "bot/bb_cells"
require_relative  "bot/bb_trade"
class PlayerStep

    def self.make_step(g, r=nil)

      return if g.curr.isbot && GameManager.bot_actions_before_roll(g)

      rr = GameUtil.random_rolls
      rr[0] = r if not r.nil?

      make_step_roll(g,rr[0],rr[1])

    end

    def self.make_step_roll(g, r1, r2)
      return if g.state != :BeginStep

      g.last_roll = [r1,r2]

      prev_pos = g.curr.pos
      curr_pos = prev_pos+r1+r2 %40

      g.logp "roll #{r1}:#{r2} (#{prev_pos}->#{curr_pos})"

      finished = step(g) #move to new pos

      if finished
          g.finish_step("_tripple_roll")
      else
          process_position(g)
      end
    end

    def self.step(g)
      r0,r1 = g.last_roll[0], g.last_roll[1]
      p = g.curr
      p.pos += r0+r1
      p.player_steps << r0*10+r1

      if check_on_tripple(p.player_steps)
          g.log "_go_jail_after_trippe"
          p.pos =10
          p.police=1
          p.player_steps << 0

          return true
      end
      if p.pos>=40 then
          p.money +=2000
          p.pos-=40
          g.log "_passed_start" if p.pos !=0
          g.log "_stayed_on_start" if p.pos ==0
      end
      return false
    end

    def self.check_on_tripple(steps)
      if steps.size>2
          return steps[-3..-1].all? {|ss| [11,22,33,44,55,66].include? ss}
      end
      return false
    end

    def self.process_position(g)
      p = g.curr

      cell = g.cells[p.pos]

      if cell.land?
          process_land(g,p,cell)

      elsif cell.type == 6 #tax
          g.to_pay(cell.rent)

      elsif cell.type == 4 #random
          g.map.take_random_card()
          process_random(g,p)

      elsif p.pos ==30
          p.pos = 10
          p.police = 1
          g.finish_step("_go_jail_after_30")
      else
          g.finish_step("_cell_nothing #{p.pos}")
      end

    end

    def self.process_land(g,p,cell)

      if cell.owner.nil?
          g.to_can_buy()

      elsif cell.owner != p.id
          if cell.ismortgage
            g.finish_step("_cell_mortgaged")
          else
            g.pay_to_user = cell.owner
            g.to_pay(cell.rent)
          end

      elsif cell.owner == p.id
          g.finish_step("_mycell")
      end

    end

    def self.process_random(g,p)
      c = g.last_rcard
      g.log "r#{c.random_group} #{c.text}"

      case c.random_group
      when 1
          p.money += c.money
          g.to_random_cell

      when 2,3
          g.move_to_cell

      when 4
          g.pay_amount = c.money*(g.players.length - 1)
          g.players.each{|x| x.money+=c.money if x.id != p.id }
          g.to_payam()

      when 5
          p.police_key+=1
          g.to_random_cell
      when -1
          g.to_pay(c.money)
      when 15
          hh = g.map.get_hotels_and_houses_count(p.id)
          g.pay_amount = hh[0] * 400 + hh[1] * 100
          g.to_payam()
      else
          g.finish_step("finish_unknown_random")
      end
    end

    def self.move_to_cell(g)
      c = g.last_rcard
      p = g.curr
      if c.random_group ==2 or c.random_group ==3
          move_after_random(g)
      end
    end

    def self.move_after_random(g)
      c = g.last_rcard
      p = g.curr

      if c.random_group ==2 and c.pos ==10
          p.pos =10
          p.police =1
          g.finish_step
      elsif c.random_group ==3
          p.pos-=3 if p.pos>3
      else
          if p.pos > c.pos
            p.pos = c.pos

            p.money+=2000
            g.log "_passed_start" if p.pos !=0
            g.log "_stayed_on_start" if p.pos ==0
          end

      end
      process_position(g)
    end
end
