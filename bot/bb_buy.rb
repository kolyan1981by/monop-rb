class BotActionsWhenBuy
    def self.factor_of_buy(g, p, cell)
        pid = p.id
        cg = cell.group
        available_money = g.player_assets(pid)

        if available_money < cell.cost then return 0 end

        myGroupsWithHouses = BBHouses.get_groups_where_need_build_houses(g, pid)
        myGroupsIds = myGroupsWithHouses.map{|gr| gr[0]}

        needBuild = myGroupsWithHouses.any?

        # find factor if i have monop with houses
        if(needBuild)
            ff = myGroupsWithHouses.map{ |gh|
                arr = mygroups_with_max_housecount(gh[0], gh[1])
                mf = arr.detect{|f| f[0] > available_money }
                mf.nil? ? -1 : mf[1]
            }.min

            return ff
        end

        gg = g.map.cells_by_group(cell.group)
        notMine = gg.select{|x| x.owner && x.owner!=pid }
        myCount = gg.select{|x| x.owner==pid }.count
        #p "factor_of_buy pid:#{pid} myCount: #{myCount}"

        aCount =0
        aOwner = nil
        if notMine.any?
            aCount = notMine.map(&:owgrcount).max
            aOwner = notMine.detect{|c| c.owgrcount == aCount}.owner
        end

        if aCount == 2 && aOwner
            asum = g.player_assets(aOwner);
            if (cg == 2 && asum > 4000) then return 4; end
            if (cg == 3 && asum > 4000) then return 3; end
            if (cg == 4 && asum > 5000) then return 2; end
            if (cg == 5 && asum > 7000) then return 2; end
        end

        manualFactor = get_manual_factor(g.bot_arules, cg, myCount,aCount, myGroupsIds)

        if !manualFactor.nil?
            return manualFactor
        end

        ftext=""

        case cg
        when 1..8,33 ; isNeedBuy =factors_an(cg,aCount); ftext="factors[an]_";
        when 11 ; isNeedBuy =factors_an(cg,aCount) if !needBuild ; ftext="factors[an]_"
        end

        if (myCount >0) then isNeedBuy = factors_my(cg,myCount) ; ftext="factors[mycount]_" end

        return isNeedBuy
    end

    def self.get_manual_factor(arules, group, myCount, aCount, groupsWithHouses)

        arules.each do |rule|
            rh = rule.groups_with_houses

            needBuild =  rh.nil? || rh.empty?

            if !rh.empty? && rh != "any"
                needBuild = (rh.split(',').map(&:to_i) & groupsWithHouses).any?
            else
                needBuild = groupsWithHouses.any? if rh == "any"
            end

            if (rule.group_id == group && rule.my_count == myCount &&
                rule.an_count == aCount && needBuild)

                return rule.factor

            end
        end

        return nil
    end

    def self.mygroups_with_max_housecount(cg, max_houses)
        factors = Hash[
            #[money range,factor_to_buy_cell]
            1=>[ [[4000,0], [6000,1.1]],
                 [[4000,0], [6000,1.2]],
                 [[4000,0], [5000,1.2]],
                 [[4000,0], [5000,1.2]],
                 [[4000,0], [5000,1.2]] ],

            2=>[ [[6000,0], [7000,1]],
                 [[6000,0], [7000,1]],
                 [[5000,0], [7000,1.2],[9000,1.2]],
                 [[4000,0], [5000,1]],
                 [[4000,0], [5000,1]] ],

            3=>[ [[9000,0], [11000,1],[13000,1.2]],
                 [[9000,0], [11000,1], [13000,1.2]],
                 [[7000,0], [9000,1],  [11000,1.2]],
                 [[4000,0], [5000,1],[7000,1.2]],
                 [[3000,0], [4000,1],[6000,1.2]] ],

            4=>[ [[9000,0], [11000,1],[13000,1.2]],
                 [[9000,0], [11000,1], [13000,1.2]],
                 [[7000,0], [9000,1],  [11000,1.2]],
                 [[4000,0], [5000,1],[7000,1.2]],
                 [[3000,0], [4000,1],[6000,1.2]] ],

            5=>[ [[9000,0], [11000,1],[13000,1.2]],
                 [[9000,0], [11000,1], [13000,1.2]],
                 [[7000,0], [9000,1],  [11000,1.2]],
                 [[4000,0], [5000,1],[7000,1.2]],
                 [[3000,0], [4000,1],[6000,1.2]] ],

            6=>[ [[9000,0], [11000,1],[13000,1.2]],
                 [[9000,0], [11000,1], [13000,1.2]],
                 [[7000,0], [9000,1],  [11000,1.2]],
                 [[4000,0], [5000,1],[7000,1.2]],
                 [[3000,0], [4000,1],[6000,1.2]] ],

            7=>[ [[9000,0], [7000,1.1],[9000,1.2]],
                 [[6000,0], [7000,1.1],[9000,1.2]],
                 [[5000,0], [7000,1.1],[9000,1.2]],
                 [[3000,0], [5000,1.1],[7000,1.2]],
                 [[2000,0], [4000,1.1],[6000,1.2]] ],

            8=>[ [[8000,0], [11000,1],[13000,1.2]],
                 [[8000,0], [10000,1],[12000,1.2]],
                 [[5000,0], [7000,1],[9000,1.2]],
                 [[1000,0], [5000,1],[7000,1.2]],
                 [[1000,0], [4000,1],[6000,1.2]] ],

        ]
        factors[cg][max_houses]
    end

    def self.factors_my(cg,myCount)
        factors = Hash[
            1=>[1, 2],
            2=>[1.1, 2, 3],
            3=>[1.1, 2, 2],
            4=>[1.1, 2, 2],
            5=>[1.1, 2, 2],
            6=>[1.1, 2, 2],
            7=>[1.1, 2, 2],
            8=>[1.1, 2],
            11=>[1.3, 1.5, 2, 2, 2],
            33=>[1.1, 1.4, 0],
        ]
        factors[cg][myCount]
    end

    def self.factors_an(cg,aCount)
        factors = Hash[
            1=>[1, 2],
            2=>[1.1, 2, 3],
            3=>[1.1, 2, 2],
            4=>[1.1, 2, 3],
            5=>[1.1, 2, 2],
            6=>[1.1, 2, 2],
            7=>[1, 2, 2],
            8=>[2, 3],
            11=>[1.3, 1.5, 2.5, 3],
            33=>[1.1, 1.4],
        ]
        factors[cg][aCount]
    end


end
