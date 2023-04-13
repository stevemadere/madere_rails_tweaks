# A Set-like object that keeps track of how many times each key has
# been added to it.
class CountedSet < Hash

  def add(member)
    if self.include?(member)
      self[member] += 1
    else
      self[member] = 1
    end
  end

  def +(set)
    result = self.clone
    set.each { |member| result.add(member) }
    result
  end

end
