require_relative  'cell'
class GameUtil
    def self.make_roll(g)
      g.last_roll = random_rolls
      g.fix_action("roll")
    end

    def self.random_rolls
      [rand(6)+1,rand(6)+1]
    end

    def self.manual_rolls(g)
      [rand(6),rand(6)]
    end

end

class FileUtil
    def self.init_game_messages(g)
      g.mtext =
      Hash[
          "_passed_start" =>["you passed the start, take $2000", "вы прошли старт и получили взятку $2000"],
          "_stayed_on_start" =>["you stayed on start, take $2000", "вы попали на старт и получили откат $2000"],
          "not_enough_money" => ["not enough money" , "не хватает денег"],
          "auc_finished" => ["auction finished" , "аукцион закончился"],
          "_random_finished" => ["random finished" , ""],
          "_cell_mortgaged" => ["cell_mortgaged" , "земля заложена"],
          "_mycell" => ["mycell" , "на своей клетке"],
          "_cell_nothing" => ["simple cell" , "пустая клетка"],
          "round_finished" => ["round finished" , "раунд закончился"],
          "player_left_game" => ["player %s left game" , "игрок %s покидает игру"],
          "player_left_auction" => ["player %s left auction" , "игрок %s покидает аукцион"],
          "game_finished" => ["game finished" , "игра закончена"],
          "player_bid" => ["player %s bid %d" , "игрок %s делает ставку %d"],
          "_paid" => ["paid" , "заплатил"],
          "_bought" => ["bought" , "купил"],
          "_build" => ["build houses" , "построил дома"],
          "_sold_houses" => ["sold houses" , "продал дома"],
          "_mortgage" => ["mortgage" , "заложил участок"],
          "_unmortgage" => ["unmortgage" , "выкупил участок"],
          "_trade_completed" => ["trade completed between %s and %s, give %s get %s",
                              "обмен состоялся между %s и %s, дает %s получает %s"],
          "_go_jail_after_tripple" => ["_go_jail_after_tripple" , "пора в камеру дружок, слишком много махинаций"],
          "_go_jail_after_30" => ["_go_jail_after_30" , "полиция устроила облаву, вы попались с наркотой и вас посадили на три хода"],
      ]

    end

    def self.init_cells_from_file(file)
      res = []
      File.open(file, "r").drop(1).each do |line|
          next if /\S/ !~ line
          c = Cell.new
          v = line.split("|")
          c.name = v[0].strip
          c.id = v[1].to_i
          c.cost = v[2].to_i
          c.type = v[3].to_i
          c.group = v[4].to_i
          c.rent_info = v[5].strip
          c.info = v[6].strip if v.size>5
          res << c

      end

      res.sort_by(&:id)
    end
    def self.init_chest_cards_from_file(g, file_path)
      res = []

      File.open(file_path, "r").drop(1).each do |line|
          next if /\S/ !~ line

          v = line.split("\t").select{ |e| !e.strip.empty?  }
          cc =ChestCard.new
          cc.random_group =v[0].to_i
          cc.type =v[1].to_i
          cc.text =v[2]
          cc.money =v[3].to_i if v.size >=4
          cc.pos =v[4].to_i if v.size >=5
          res<< cc
      end
      g.community_chest =res.select{ |e| e.type ==1  }
      g.chance_chest =res.select{ |e| e.type ==2  }
    end

    def self.init_chest_cards(g)
      community = []
      chance = []

      community<< ChestCard.new(:random_group => -1,  :text=>"need pay bank",:money=>100)

      community<< ChestCard.new(:random_group =>1, :text=>"get money $100",:money=>100)
      community<< ChestCard.new(:random_group =>1, :text=>"get money $1.5K",:money=>1500)
      community<< ChestCard.new(:random_group =>1, :text=>"get money $2K",:money=>2000)

      community<< ChestCard.new(:random_group =>2, :text=>"go to trans", :pos=>5)
      community<< ChestCard.new(:random_group =>5, :text=>"Get out of jail free")

      community<< ChestCard.new(:random_group =>15, :text=>"You are assessed for street repairs – $100 per house, $400 per hotel",:money=>0)

      chance<< ChestCard.new(:random_group =>2, :text=>"Advance to Go", :pos=>0)
      chance<< ChestCard.new(:random_group =>2, :text=>"go to Police", :pos=>10)
      chance<< ChestCard.new(:random_group =>2, :text=>"go to", :pos=>11)
      chance<< ChestCard.new(:random_group =>2, :text=>"go to",:pos=>24)
      chance<< ChestCard.new(:random_group =>2, :text=>"go to",:pos=>39)

      chance<< ChestCard.new(:random_group =>3, :text=>"go to 3 cell back")
      chance<< ChestCard.new(:random_group =>4, :text=>"Pay each player $500", :money=>500)

      g.community_chest =community
      g.chance_chest =chance

    end
    def self.init_trades_from_file(file)
      res = []
      i=0
      File.open(file, "r").drop(1).each do |line|
          next if /\S/ !~ line

          t = TRule.new
          t.id = i
          i+=1
          arr = line.split(";")
          count = arr.length

          if count >1

            mm1 = arr[0].split("-")
            t.get_land = mm1[0].to_i
            t.get_count = mm1[1].to_i
            t.my_count = mm1[2].to_i

            mm2 = arr[1].split("-")
            t.give_land = mm2[0].to_i
            t.give_count = mm2[1].to_i
            t.your_count = mm2[2].to_i

          end

          if count >2
            mm3 = arr[2].split("-")

            t.get_money =  mm3[0].to_i
            t.give_money =  mm3[1].to_i

          end
          t.money_factor = count>3 ? arr[3].to_f : 1

          t.disabled = (arr[4].strip == "d=1") if count > 4

          res << t if count > 4 && !t.disabled
      end
      res
    end

    def self.init_aucrules_from_file(file)
      res = []
      File.open(file, "r").drop(1).each do |line|
          next if /\S/ !~ line
          a = ARule.new
          arr = line.split(";")
          a.group_id = find_value('gid=', arr).to_i
          a.my_count = find_value('myc=', arr).to_i
          a.an_count = find_value('anc=', arr).to_i
          a.my_money = find_value('money=', arr).to_i
          a. groups_with_houses = find_value('nb=', arr)
          a.factor = find_value('fac=', arr).to_f

          res << a

      end
      res
    end

    def self.find_value(val, arr)
      str = arr.detect{|x| x.start_with?(val)}
      str.gsub(val, "")
    end
    #puts read_file("lands.txt")
end
