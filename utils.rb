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
          c.arenda_info = v[5].strip
          res << c

      end

      res.sort_by(&:id)
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
