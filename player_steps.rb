require_relative  "bot/bb_buy"
require_relative  "bot/bb_houses"
require_relative  "bot/bb_cells"
require_relative  "bot/bb_trade"

class PlayerStep

  def self.make_step(g, r=nil)

    return if g.curr.isbot && GameManager.bot_actions_before_roll(g)

    g.curr.update_timer

    if g.is_manual_roll_mode
      g.players.each { |pl| pl.manual_roll = rand(6)+1 if pl.bot?  }

      sum =0
      g.players.each{|pl| sum+= pl.manual_roll if pl.id != g.curr.id}
      r2 = sum!=0 ? (sum.to_f/(g.players.size-1)).round :  rand(6)+1
      rr = [ g.curr.manual_roll, r2 ]
    else
      rr = [rand(6)+1,rand(6)+1]
      #rr = [1,2]
      rr[0] = r if not r.nil?
    end

    make_step_roll(g,rr[0],rr[1])

  end

  def self.make_step_roll(g, r1, r2)
    return if g.state != :BeginStep

    g.last_roll = [r1,r2]

    prev_pos = g.curr.pos

    result = step(g) #move to new pos

    if result == 'go' #|| result =='pay500_go'
      pl = g.curr
      pl.pos += r1+r2
      pl.player_steps << r1*10+r2

      check_pass_start(g)

      g.log g.l "(#{prev_pos}->#{g.curr.pos}), вы попали на [#{g.cells[g.curr.pos].name}]", "(#{prev_pos}->#{g.curr.pos}), you landed on [#{g.cells[g.curr.pos].name}]"
      g.logx "(#{g.curr.name},#{g.curr.money}) roll #{r1}:#{r2}, (#{prev_pos}->#{g.curr.pos})"

      process_position(g)

    elsif result =='pay500_go'
    else
      g.finish_step(result)
    end
  end

  def self.step(g)

    r1,r2 = g.last_roll[0], g.last_roll[1]

    pl = g.curr

    if pl.isbot && pl.police>0 && calc_jail_exit(g)
      pl.money-=500
      pl.police=0
      before_roll = g.l "#{g.curr.name} заплатил $500 чтобы выйти из тюрьмы <br />", "you paid $500 to exit from jail<br />"
      g.log "_paid_500_and_go_from_jail"
    end

    img = "<img src='/game/images/r%s.png' >"
    rolls= g.isconsole ? "#{r1}:#{r2}" :(img+img) % g.last_roll

    g.round_message = (before_roll||'')+ (g.l "раунд #{g.round}: #{g.curr.name} выкинул " + rolls , "round #{g.round}: #{g.curr.name} rolled " + rolls)

    g.log (before_roll||'')+ (g.l "#{g.curr.name} выкинул #{rolls}", "#{g.curr.name} rolled #{rolls}")


    if pl.police>0

      if r1==r2
        g.round_message += g.l "<br />вы выходите из тюрьмы по дублю", "<br />you released from jail because of double roll"
        pl.police ==0
      else

        pl.police +=1
        if pl.police ==4
          g.round_message += g.l "<br />вы должны заплатить $500 чтобы выйти из тюрьмы","<br />you must pay $500 to go from jail"
          g.to_pay(500, false)
          return "_pay500_go"
        else
          g.round_message += g.l "<br />вы пропускаете ход в тюрьме", "<br />you passed turn"
          return "_police_:not_roll_doudle"
        end

      end

    end



    if check_on_tripple(pl.player_steps)
      g.log "_go_jail_after_trippe"
      pl.pos =10
      pl.police=1
      pl.player_steps << 0

      return "_tripple_roll"
    end

    return 'go'
  end

  def self.calc_jail_exit(g)

    mypid = g.curr.id
    f4= g.map.cells_by_group(4).any? { |c| c.owner.nil?  }
    f5= g.map.cells_by_group(5).any? { |c| c.owner.nil?  }

    m4 = g.map.cells_by_group(4).all? { |c| c.active? && c.monopoly? && c.owner != mypid  }
    m5 = g.map.cells_by_group(5).all? { |c| c.active? && c.monopoly? && c.owner != mypid  }
    m6 = g.map.cells_by_group(6).all? { |c| c.active? && c.monopoly? && c.owner != mypid  }
    m7 = g.map.cells_by_group(7).all? { |c| c.active? && c.monopoly? && c.owner != mypid }

    return false if m4||m5
    return true if f4||f5
    return false if m6

    g.curr.money>500
  end
  def self.check_on_tripple(steps)
    if steps.size>2
      return steps[-3..-1].all? {|ss| [11,22,33,44,55,66].include? ss}
    end
    return false
  end

  def self.check_pass_start(g)
    p = g.curr
    if p.pos>=40 then
      p.money +=2000
      p.pos-=40
      g.log "_passed_start" if p.pos !=0
      g.log "_stayed_on_start" if p.pos ==0
    end
  end

  def self.change_pos_and_process_position(g)
    r = g.last_roll
    pl = g.curr
    pl.pos += r[0]+r[1]
    pl.player_steps << r[0]*10 + r[1]
    process_position(g)
  end

  def self.process_position(g)
    p = g.curr

    cell = g.cells[p.pos]
    g.round_message += g.l "<br/> вы попали на [#{cell.name}]", "<br/> you landed on [#{cell.name}]"

    if cell.land?
      process_land(g,p,cell)

    elsif cell.type == 6 #tax
      g.to_pay(cell.rent)

    elsif cell.type == 4 #random
      process_random(g,p)

    elsif p.pos ==30
      p.pos = 10
      p.police = 1
      g.round_message += "<br/> #{g.get_text('_go_jail_after_30')}"
      g.finish_step("_go_jail_after_30")
    else
      g.finish_step("")#g.finish_step("_cell_nothing #{p.pos}")
    end

  end

  def self.process_land(g,p,cell)

    if cell.owner.nil?
      g.to_can_buy()

    elsif cell.owner != p.id
      if cell.ismortgage
        g.round_message += "<br/> #{g.get_text '_cell_mortgaged'}"
        g.finish_step("_cell_mortgaged")
      else
        g.pay_to_user = cell.owner
        g.round_message += g.l "<br />заплатите ренту $#{cell.rent}","<br />pay rent $#{cell.rent}"
        g.to_pay(cell.rent)
      end

    elsif cell.owner == p.id
      g.finish_step("_mycell #{cell.name}" )
    end

  end

  def self.process_random(g,p)

    g.map.take_random_card()
    c = g.last_rcard
    g.log "#{c.text}"
    g.logx "random rgroup:#{c.random_group}"
    g.round_message += "<br/>#{g.get_text('_random_took_card')} [#{c.text}]"

    case c.random_group
    when 1
      p.money += c.money
      g.to_random_cell
    when 12
      g.to_pay(c.money)
      g.to_random_cell

    when 2,3
      g.move_to_cell
      #PlayerStep.move_after_random(g)

    when 4
      g.pay_amount = c.money*(g.players.length - 1)
      g.players.each{|x| x.money+=c.money if x.id != p.id }
      g.to_payam()

    when 5
      p.police_key+=1
      g.to_random_cell

    when 15
      hh = g.map.get_hotels_and_houses_count(p.id)
      g.pay_amount = hh[0] * 400 + hh[1] * 100
      g.to_payam()
    else
      g.finish_step("finish_unknown_random")
    end

    #g.last_rcard = nil
  end

  def self.move_after_random(g)
    c = g.last_rcard
    p = g.curr

    if c.random_group ==2 and c.pos ==10
      p.pos =10
      p.police =1
      g.logx "catch_by_police"
      g.finish_step("")
    elsif c.random_group ==3
      p.pos-=3 if p.pos>3
      process_position(g)
    else
      if p.pos > c.pos
        p.money+=2000
        g.log "_passed_start" if p.pos !=0
        g.log "_stayed_on_start" if p.pos ==0
      end
      p.pos = c.pos
      process_position(g)
    end

  end
end
