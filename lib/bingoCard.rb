class BingoCell < String
  def covered?
    return self == 'x'
  end
end

class BingoCard
  # rawdata is in the form [[row0], ..., [row-n]].
  # row-n is in the form [BingoCell-0, ..., BingoCell-m].
  def initialize(rawdata)
    @cells = rawdata.map {|row| row.map {|s| BingoCell.new(s)}}
    #pp @cells
  end

  # Returns true iff the card has a completely covered row, column, or diagonal.
  # If row and col are non-nil, checks only that row and column, and diagonal 
  # if row, col lies on either diagonal.
  def bingo?(row=nil, col=nil)
    if (row) then
      return true if self.covered_row?(row)
    else
      (0..4).each do |i|
        return true if self.covered_row?(i)
      end
    end

    if (col) then
      return true if self.covered_column?(col)
    else
      (0..4).each do |i|
        #pp self.column(i)
        return true if self.covered_column?(i)
      end
    end

    if (row.nil? || col.nil?) then
      return covered_rising_diagonal? || covered_falling_diagonal?
    elsif (row == col) then
      return covered_falling_diagonal?
    elsif (row + col == @cells.length - 1) then
      return covered_rising_diagonal?
    end
  end

  def covered_row?(i)
    self.row(i).all? {|cell| cell.covered?}
  end

  def covered_column?(i)
    self.column(i).all? {|cell| cell.covered?}
  end

  def covered_rising_diagonal?
    #pp self.risingDiagonal
    self.risingDiagonal.all? {|cell| cell.covered?}
  end

  def covered_falling_diagonal?
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
