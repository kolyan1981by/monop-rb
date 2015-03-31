class Cell

  attr_accessor :id, :name, :type, :group, :info
  attr_accessor :owner, :owgrcount
  attr_accessor :cost
  attr_accessor :rent_info, :houses_count, :ismortgage
  attr_accessor :random_group
  def initialize()
    @owgrcount = 0
    @owner = nil
    @ismortgage = false
    @houses_count = 0
  end

  def rent
    if type == 6 then return need_pay(0) end
    if group == 11 then return need_pay(owgrcount-1) end
    if group == 33 then return owgrcount==2 ? 500: need_pay(0) end
    if monopoly? && houses_count==0 then
      return need_pay(0)*2
    else
      return need_pay(houses_count||0)
    end
    need_pay(0)
  end

  def need_pay(index)
    if rent_info == nil || index<0  then return 0 end
    rent_info.split(';')[index].to_i
  end

  def land?
    type ==1 || type ==2 || type ==3
  end

  def active?
    ! @ismortgage
  end
  def mortg?
    @ismortgage
  end

  def monopoly?
    if type != 1 ; return false end
    if group >= 2 && group <= 7 then return owgrcount == 3 end
    if group==1 || group ==8 then return owgrcount == 2 end
    false
  end

  def can_build?
    @houses_count<5
  end

  def house_cost
    case group
    when 1,2
      500
    when 3,4
      1000
    when 5,6
      1500
    when 7,8
      2000
    else
      0
    end
  end

  def house_cost_when_sell
    house_cost / 2
  end

  def mortgage_amount
    cost / 2
  end

  def unmortgage_amount
    (cost / 2 * 1.1).to_i
  end
end
