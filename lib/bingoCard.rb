class BingoCell < String
  def covered?
    return self == 'x'
  end
end

class BingoCard
  def initialize(rawdata)
    @cells = rawdata.map {|row| row.map {|s| BingoCell.new(s)}}
    #pp @cells
  end

  def bingo?
    (0..4).each do |i|
      return true if self.covered_row?(i)
    end

    (0..4).each do |i|
      #pp self.column(i)
      return true if self.covered_column?(i)
    end

    return risingDiagonal? || fallingDiagonal?
  end

  def covered_row?(i)
    self.row(i).all? {|cell| cell.covered?}
  end

  def covered_column?(i)
    self.column(i).all? {|cell| cell.covered?}
  end

  def risingDiagonal?
    #pp self.risingDiagonal
    self.risingDiagonal.all? {|cell| cell.covered?}
  end

  def fallingDiagonal?
    self.fallingDiagonal.all? {|cell| cell.covered?}
  end

  # Return array of cells in row i
  def row(i)
    #pp @cells[i]
    @cells[i]
  end

  # Return array of cells in column i
  def column(i)
    #pp @cells[i]
    (0..(@cells.length-1)).map {|r| @cells[r][i]}
  end

  def risingDiagonal
    c = 0 # col num
    (1..(@cells.length)).map do |r|
      #puts "r=#{r}, c=#{c}"
      k = c
      c += 1
      @cells[-r][k]
    end
  end

  def fallingDiagonal
    c = 0 # col num
    (0..(@cells.length-1)).map do |r|
      #puts "r=#{r}, c=#{c}"
      k = c
      c += 1
      @cells[r][k]
    end
  end
end
