class BotBrainCells
    def self.mortgage_sell(g, p, amount)
      return true if p.money>=amount

      #1 - mortage non monopoly lands
      mortgage(g, p, amount)

      #2 - sell houses
      BBHouses.sell_houses(g, p, amount)

      #3 -mortage monopoly without houses
      mortgage(g, p, amount, true)

      return p.money >= amount

    end

    def self.mortgage(g, p, amount, inclMonop=false)

      return true if p.money >= amount

      cells = g.map.cells_by_user(p.id).select{|x| x.active?}

      #select non monopoly cells-type1
      lands = cells.select{|x|  !x.monopoly? && x.type == 1}

      #select trans and power cells
      transPower = cells.select{|x| x.type == 2 || x.type == 3}

      all_cells = lands+transPower

      if inclMonop
          landsMon000 = cells.select{|x| x.monopoly? && x.houses_count==0}
          all_cells += landsMon000
      end

      text=""

      cells.each do |cell|
          break if p.money >= amount
          p.money += cell.mortgage_amount
          cell.ismortgage = true
          text+="_"+cell.id.to_s


      end

      g.fix_action("_mortgage #{text}") if text != ""

      return p.money >= amount

    end

    def self.unmortgage_cells(g)
      text = ""
      cells=[]
      p = g.curr

      needBuild = BBHouses.need_build_houses?(g,p.id)

      trans = g.map.cells_by_user_by_group(p.id,11)

      monop_cells = g.map.cells_by_user(p.id).select{|x| x.monopoly? && x.ismortgage}

      cells = trans.length >2 ? trans + monop_cells : monop_cells + trans

      cells = cells-trans if true

      cells.each do |cell|
          next if cell.active?
          sum = cell.unmortgage_amount
          break if p.money < sum

          p.money -= sum
          cell.ismortgage = false
          text += "_#{cell.id}"

      end

      g.fix_action("_unmortgage #{text}") if text != ""

    end
end
