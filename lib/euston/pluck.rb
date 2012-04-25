module Enumerable
  def pluck method, *args
    map { |x| x.send method, *args }
  end
end
