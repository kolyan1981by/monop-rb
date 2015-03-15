require_relative  'cell'
module GameUtil


  def self.random_rolls
    [rand(6)+1,rand(6)+1]
  end

  def self.time_roll
    (Time.now.to_f*10).to_i%6+1
  end

end
class GLog



end
class FileUtil
  def self.init_game_messages(g)
    g.mtext =
    {
      "_passed_start" =>["you passed the start, take $2000", "вы прошли старт и получили взятку $2000"],
      "_stayed_on_start" =>["you stayed on start, take $2000", "вы попали на старт и получили откат $2000"],
      "not_enough_money" => ["not enough money" , "не хватает денег"],
      "auc_finished" => ["auction finished" , "аукцион закончился"],
      "_random_finished" => ["random finished" , ""],
      "_cell_mortgaged" => ["cell_mortgaged" , "земля заложена"],
      "_mycell" => ["you are on own cell " , "вы на своей земле "],
      "_cell_nothing" => ["simple cell" , "пустая клетка"],
      "round_finished" => ["round finished" , "раунд закончился"],
      "player_left_game" => ["player %s left game" , "игрок %s покидает игру"],
      "_player_left_auction" => ["player %s left auction" , "игрок %s покидает аукцион"],
      "_roll" => ["roll" , "бросил кости"],
      "game_finished" => ["game finished" , "игра закончена"],
      "_player_bid" => ["player %s bid %d" , "игрок %s делает ставку %d"],
      "_paid" => ["paid" , "вы заплатили"],
      "_bought" => ["bought" , "вы купили землю"],
      "_build" => ["build houses" , "вы построили дома"],
      "_sold_houses" => ["sold houses" , "вы продали дома"],
      "_mortgage" => ["mortgage" , "вы заложили участок"],
      "_unmortgage" => ["unmortgage" , "вы выкупили участок"],
      "_trade_completed" => ["trade completed between %s and %s, give %s get %s",
                             "обмен состоялся между %s и %s, предлагал %s, получил %s"],
      "_trade_not_completed" => ["trade failed between %s and %s, give %s get %s",
                                 "обмен провалился между %s и %s, предлагал %s, хотел получить %s"],
      "_go_jail_after_30" => ["_go_jail_after_30" , "полиция устроила облаву, вы попались с наркотой и вас посадили на три хода"],
      "no_winners" => ["no winners" , "победителей нет"],
      "winner" => ["winner" , "победитель "],
      "_go_jail_after_trippe" => ["_go_jail_after_trippe" , "сложная логистика у ваших подчиненных, посидите три хода в тюрьме"],
      "police_:not_roll_doudle" => ["police_:not_roll_doudle" , "вы не выкинули дупль, посидите еще ход в тюряге"],
      "pay500_go" => ["pay500_go" , "вы заплитили $500 чтобы освободиться"],
      "_tripple_roll" => ["_tripple_roll" , "вы выкинули три дупля подряд и перемещаетесь в камеру"],
      "paid_500_and_go_from_jail" => ["paid_500_and_go_from_jail" , "вы заплатили $500 и вышли из тюрьмы"],

    }

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
      c.info = v[6].strip if v[6]
      res << c

    end

    res.sort_by(&:id)
  end
  def self.init_chest_cards_from_file(g, file_path)
    res = []

    File.readlines(file_path).drop(1).each do |line|
      next if /\S/ !~ line

      v = line.split("|").select{ |e| !e.strip.empty?  }
      cc =ChestCard.new
      cc.random_group =v[0].to_i
      cc.type =v[1].to_i
      cc.text =v[2].strip
      cc.money =v[3].to_i if v[3]
      cc.pos =v[4].to_i if v[4]
      res<< cc
    end
    g.community_chest =res.select{ |e| e.type ==1  }
    g.chance_chest =res.select{ |e| e.type ==2  }
  end


  def self.init_trades_from_file(file)
    res = []
    i=0
    File.readlines(file).drop(1).each do |line|
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

      rule = line.split(";").map {|pair| pair.split("=",-1) }.to_h
      a.group_id =  rule["gid"].to_i
      a.my_count =  rule["myc"].to_i
      a.an_count =  rule["anc"].to_i
      a.my_money =  rule["money"].to_i
      a.groups_with_houses =  rule["nb"]
      a.factor =  rule["fac"].to_f
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
