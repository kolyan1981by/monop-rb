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
      g.player.step
      g.logp "roll #{r1}:#{r2} (#{prev_pos}->#{g.curr.pos})"

      process_position(g)
    end

    def self.process_position(g)
      p = g.curr
      g.logd "process_position #{p.pos}"

      cell = g.cells[p.pos]

      if cell.land?
          process_land(g,p,cell)

      elsif cell.type == 6
          g.to_pay(cell.rent)

      elsif cell.type == 4
          g.map.take_random_card()
          process_random(g,p)

      else
          g.finish_step("cell_#{p.pos}")
      end

    end

    def self.process_land(g,p,cell)

      if cell.owner.nil?
          g.to_can_buy()

      elsif cell.owner != p.id
          if cell.ismortgage
            g.finish_step("cell_mortgaged")
          else
            g.pay_to_user = cell.owner
            g.to_pay(cell.rent)
          end

      elsif cell.owner == p.id
          g.finish_step("mycell")
      end
      g.logd "pl_step.end_processland"
    end

    def self.process_random(g,p)
      c = g.last_rcard
      case c.random_group
      when 1
          p.money += c.money
          g.log c.text
          g.to_random_cell

      when 2,3
          g.move_to_cell

      when 4
          g.pay_amount = c.money*(g.players.length - 1)
          g.log c.text
          g.players.each{|x| x.money+=c.money if x.id != p.id }
          g.to_payam()

      when 5
          p.police_key+=1
          g.to_random_cell
      when -1
          g.to_pay(c.money)
      when 15
          g.log c.text
          hh = g.map.get_hotels_and_houses_count(p.id)
          g.pay_amount = hh[0] * 400 + hh[1] * 100
          g.to_payam()
      else
          g.finish_step("finish_unknown_random")
      end
      g.logd "pl_step.end.process_random"
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

      if c.random_group ==2 and c.pos ==1
          p.pos =10
          p.police =1
          g.log c.text
          g.finish_step
      else
          if c.random_group ==3
            g.log c.text
            p.pos-=3 if p.pos>3
          else
            g.log "#{c.text} #{c.pos}"
            if p.pos > c.pos
                p.money+=2000
                g.logp g.lang_en? ? "you passed the start" : "вы прошли старт"
            end
            p.pos = c.pos
          end
          process_position(g)
      end
      g.logd "pl_step.end.move_after_random"
    end

end
