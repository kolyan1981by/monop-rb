require_relative  "cell"
require_relative  "game"
require_relative  "utils"
require_relative  'player'
require_relative  'player_steps'
class Map
    attr_accessor :id, :g
    def initialize(g)
      @g = g
    end

    def cells_by_user(pid)
      @g.cells.select {|c| c.owner == pid }
    end

    def cells_by_group(group)
      @g.cells.select {|c| c.group == group }
    end

    def cells_by_type(types)
      @g.cells.select {|c| types.include? c.type }
    end

    def cells_by_user_by_group(pid, group)
      @g.cells.select {|c| c.owner == pid && c.group == group }
    end

    def cells_by_user_by_type(pid, type)
      @g.cells.select {|c| c.owner == pid && c.type == type }
    end

    def get_hotels_and_houses_count(pid)

      cc = cells_by_user_by_type(pid,1)
      houses = cc.select{|x| x.houses_count.between?(1,4)}.map(&:houses_count).inject(:+)
      hotels = cc.select{|x| x.houses_count ==5 }.count
      [hotels||0, houses||0]

    end

    def set_owner(p,cell)
      cell.owner = p.id
      cell.ismortgage = false
      p.money -= cell.cost
      update_map
    end

    def update_map
      groups = g.cells.select {|c| c.land? && c.owner }
      .group_by{ |c| [c.group, c.owner] }
      .map {|k,v| [k, v]}

      groups.each do |gr|
          gr[1].each{|c| c.owgrcount = gr[1].length}
      end
    end

    def take_random_card
      #chance group
      if [7,22,36].include? g.curr_cell.id

          count = g.chance_chest.length
          g.last_rcard = g.chance_chest[rand(count)]
      else

          count = g.community_chest.length
          g.last_rcard = g.community_chest[rand(count)]

      end
    end

    def move_to_cell
      if curr.isbot
          PlayerStep.move_to_cell(@g)
          @g.finish_step
      else
          @g.state = :MoveToCell
      end

    end



end
