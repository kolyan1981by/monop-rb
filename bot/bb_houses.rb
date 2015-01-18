class BBHouses
    def self.need_build_houses?(g, pid)
      g.map.cells_by_user(pid).any?{|c| c.type==1 && c.houses_count > 0 && c.houses_count<4}
    end

    def self.get_groups_where_need_build_houses(g, pid , maxcount =3)
      g.map.cells_by_user(pid)
      .select{|c| c.type==1 && c.houses_count> 0 && c.houses_count <= maxcount}
      .group_by(&:group).map{|k,v| [k, v.map(&:houses_count).max ]}
    end

    def self.build_houses(g, sum, group=nil)
      p = g.curr

      groupCells = g.map.cells_by_user_by_type(p.id, 1).select{|c| c.monopoly?}.group_by(&:group)
      .select{|k,v|  v.all?{|c| c.active?} }

      if !group.nil?
          groupCells = groupCells.select{|gr| gr[0] == group}
      end
      text=""
      builded_sum = 0

      groupCells.sort_by{|k,v| v.max_by(&:houses_count).houses_count}.reverse.each do |gr|

          cost = gr[1].first.house_cost

          while ( BotBrainCells.mortgage(g,p,cost) && gr[1].any?{|c| c.can_build?} )

            gr[1].sort_by(&:houses_count).each do |cell|

                if builded_sum+cost > sum
                  g.fix_action("build#{text}") if text != ""
                  return
                end

                if BotBrainCells.mortgage(g,p,cost) && cell.can_build?
                  cell.houses_count+=1
                  p.money -= cell.house_cost
                  builded_sum += cost
                  text = text+ "_" + cell.id.to_s
                end
            end

          end
      end

      g.fix_action("build#{text}") if text != ""
    end

    def self.sell_houses(g, p, amount)

      text = "";
      cells = g.map.cells_by_user(p.id).select{|x| x.monopoly? && x.active?}

      loop  do
          break if p.money >= amount
          break if !cells.select{|x| x.houses_count>0}.any?

          cells.sort_by(&:houses_count).reverse.each do |cc|
            break if p.money >= amount

            if cc.houses_count > 0
                cc.houses_count-=1
                p.money += cc.house_cost_when_sell
                text = text + "_" + cc.id.to_s
            end
          end

      end

      g.fix_action("sold_houses#{text}") if text != ""

    end
end
