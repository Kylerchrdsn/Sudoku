#! /usr/bin/env ruby
require 'pp'

class Cell
  attr_accessor :tmp_fill, :possible, :value
  #*******************************
  def initialize val = 0
    @value    = val
    @tmp_fill = false
    @possible = []
    @possible.delete(@value)
  end
  #*******************************
  def to_s
    @value.to_s
  end
end

class Puzzle
  attr_reader :row_solve_called, :box_solve_called, :col_solve_called
  #<<helpers
    #*******************************
    def initialize puzzle = nil
      @puzzle = []
      @attempt = 0
      @row_solve_called = 0
      @col_solve_called = 0
      @box_solve_called = 0 

      if !puzzle.empty?
        puzzle.each{|r| @puzzle << r.map{|c| Cell.new(c) }}
      else
        9.times{
          _row = []
          9.times{ _row << Cell.new }
          @puzzle << _row
        }
      end
    end
    #*******************************
    def [] index
      @puzzle[index]
    end
    #*******************************
    def print
      pp @puzzle.map{|r| r.map{|c| c.value }}
    end
    #<<row
      def rows; @puzzle end
      def row(i); @puzzle[i].dup end
    #row
    #<<column
      #*******************************
      def column j
        result = []
        0.upto(8){|i| result << @puzzle[i][j] }
        result
      end
      #*******************************
      def columns
        results = []
        0.upto 8 do |j|
          col = []
          0.upto 8 do |i|
            col << @puzzle[i][j]
          end
          results << col
        end
        results
      end
    #column
    #<<box
      #*******************************
      def box i, j, num = nil
        result  = []
        if !num.nil?
          b_num = num
        else
          b_sub_i = b_i i
          b_sub_j = b_j j
          b_num   = b(b_sub_i, b_sub_j)
        end
        
        cols    = b_cols b_num
        r       = b_rows b_num
        r.each{|ii|
          cols.each{|jj|
            result << @puzzle[ii][jj]
          }
        }
        result
      end
      #*******************************
      def b b_sub_i, b_sub_j
        (3*b_sub_i)+b_sub_j
      end
      #*******************************
      def b_rows b_num
        [0+3*(b_num/3),1+3*(b_num/3),2+3*(b_num/3)]
      end
      #*******************************
      def b_cols b_num
        [0+3*(b_num%3),1+3*(b_num%3),2+3*(b_num%3)]
      end
      #*******************************
      def b_i i
        if [0,1,2].include?(i)
          0
        elsif [3,4,5].include?(i)
          1
        else
          2
        end
      end
      alias :b_j :b_i
    #box
  #helpers

  #<<solve
    #*******************************
    def solved?
      result = true
      @puzzle.each{|r| result = false if r.map{|i| i.value}.include?(0) }
      result
    end
    #*******************************
    def solve
      orig = @puzzle.map{|r| r.map{|c| c.value } }
      3.times{ 
        if !solved? 
          rows.each_with_index{|r, i| solve_row(r, i) }
          @row_solve_called += 1
        end
      }
      3.times{ 
        if !solved? 
          columns.each_with_index{|c, j| solve_column(c, j) }
          @col_solve_called += 1
        end
      }
      3.times{ 
        if !solved? 
          0.upto(8){|num| solve_box(num) }
          @box_solve_called += 1
        end
      }
      if orig == @puzzle.map{|r| r.map{|c| c.value } }
        raise 'Cannot solve!'
      end

      until solved? || @attempt == 1000
        3.times{ 
          if !solved? 
            rows.each_with_index{|r, i| solve_row(r, i) }
            @row_solve_called += 1
          end
        }
        3.times{ 
          if !solved? 
            columns.each_with_index{|c, j| solve_column(c, j) }
            @col_solve_called += 1
          end
        }
        3.times{ 
          if !solved? 
            0.upto(8){|num| solve_box(num) }
            @box_solve_called += 1
          end
        }
        @attempt += 1
      end
    end
    #*******************************
    def solve_box num
      ox = box nil, nil, num
      o  = ox.dup.map{|i| i.value }
      tmp_not_needed = (ox.map{|x| x.tmp_fill == true ? x.possible : nil }.compact)
      tmp_not_needed = (tmp_not_needed.empty? ? [] : tmp_not_needed.first)
      needs = ((1..9).to_a-o)-tmp_not_needed

      roes = b_rows num
      cols = b_cols num

      roes.each{|i|
        cols.each{|j|
          cell = @puzzle[i][j]
          if cell.value == 0
            # Check column #
            possible = needs
            in_row = row(i)
            in_row.map!{|c| c.value == 0 ? nil : c.value }.compact!
            possible -= in_row
            # Check box #
            in_col   = column(j)
            in_col.map!{|c| c.value == 0 ? nil : c.value }.compact!
            possible -= in_col
            # solve, if possible #
            cell.possible = possible
            if possible.length == 1
              cell.value = possible.first
              needs.delete(possible.first)
            end

            if needs.length == 1
              cell.value = needs.first
            end
          end
        }
      }

      needs.each do |p|
        possible_cells = []
        roes.each{|i|
          cols.each{|j|
            possible_cells << @puzzle[i][j] if @puzzle[i][j].possible.include?(p)
          }
        }
        possible_cells.first.value = p if possible_cells.length == 1
      end

      ox.each{|_cell| _cell.tmp_fill = false }
      matches = find_matches(ox)
      unless matches.empty?
        matches.each{|m| m.tmp_fill = true }
      end
    end
    #*******************************
    def solve_column c, j
      col   = c.dup.map{|i| i.value }
      tmp_not_needed = (c.map{|x| x.tmp_fill == true ? x.possible : nil }.compact)
      tmp_not_needed = (tmp_not_needed.empty? ? [] : tmp_not_needed.first)
      needs = ((1..9).to_a-col)-tmp_not_needed
      col.delete(0)

      c.each_with_index{|cell, i|
        if cell.value == 0 && !cell.tmp_fill
          # Check column #
          possible = needs
          in_row = row(i)
          in_row.map!{|c| c.value == 0 ? nil : c.value }.compact!
          possible -= in_row
          # Check box #
          in_box = box(i, j)
          in_box.map!{|c| c.value == 0 ? nil : c.value }.compact!
          possible -= in_box
          # solve, if possible #
          cell.possible = possible
          if possible.length == 1
            cell.value = possible.first
            needs.delete(possible.first)
          end

          if needs.length == 1
            cell.value = needs.first
          end
        end
      }

      needs.each do |p|
        possible_cells = []
        c.each do |cell|
          possible_cells << cell if cell.possible.include?(p)
        end
        possible_cells.first.value = p if possible_cells.length == 1
      end

      c.each{|_cell| _cell.tmp_fill = false }
      matches = find_matches(c)
      unless matches.empty?
        matches.each{|m| m.tmp_fill = true }
      end
    end
    #*******************************
    def solve_row r, i
      _row    = r.dup.map{|ind| ind.value }
      tmp_not_needed = (r.map{|x| x.tmp_fill == true ? x.possible : nil }.compact)
      tmp_not_needed = (tmp_not_needed.empty? ? [] : tmp_not_needed.first)
      needs  = ((1..9).to_a-_row)-tmp_not_needed
      _row.delete(0)

      r.each_with_index{|cell, j|
        if cell.value == 0
          # Check column #
          possible = needs
          in_col   = column(j)
          in_col.map!{|c| c.value == 0 ? nil : c.value }.compact!
          possible -= in_col
          # Check box #
          in_box = box(i, j)
          in_box.map!{|c| c.value == 0 ? nil : c.value }.compact!
          possible -= in_box
          # solve, if possible #
          cell.possible = possible
          if possible.length == 1
            cell.value = possible.first
            needs.delete(possible.first)
          end

          if needs.length == 1
            cell.value = needs.first
          end
        end
      }

      needs.each do |p|
        possible_cells = []
        r.each do |cell|
          possible_cells << cell if cell.possible.include?(p)
        end
        possible_cells.first.value = p if possible_cells.length == 1
      end

      r.each{|_cell| _cell.tmp_fill = false }
      matches = find_matches(r)
      unless matches.empty?
        matches.each{|m| m.tmp_fill = true }
      end
    end
  #solve

  def find_matches obj
    result = []
    obj.each{|cell|
      if cell.value == 0
        need_to_match = cell.possible.dup
        matches = [cell]
        obj.each{|c|
          unless c == cell
            intersect = c.possible&need_to_match
            if intersect == need_to_match && c.possible.length == need_to_match.length
              matches << c
            end
          end
        }
        if matches.length == need_to_match.length
          result = matches
          break
        end
      end
    }
    return result
  end
end

=begin
  # Easy Puzzle  
  t = Puzzle.new([[0,0,0,0,6,0,0,3,0],[2,4,0,0,0,0,1,0,0],[0,0,7,0,0,2,0,0,8],[0,0,1,4,0,0,3,0,9],[7,0,0,3,1,9,0,0,2],[3,0,6,0,0,7,5,0,0],[5,0,0,7,0,0,8,0,0],[0,0,2,0,0,0,0,1,3],[0,7,0,0,2,0,0,0,0]])
  # Medium Puzzle
  t = Puzzle.new([[],[],[],[],[],[],[],[],[]])
  # Hard Puzzle
  t = Puzzle.new([[0,0,0,2,0,0,0,6,3],[3,0,0,0,0,5,4,0,1],[0,0,1,0,0,3,9,8,0],[0,0,0,0,0,0,0,9,0],[0,0,0,5,3,8,0,0,0],[0,3,0,0,0,0,0,0,0],[0,2,6,3,0,0,5,0,0],[5,0,3,7,0,0,0,0,8],[4,7,0,0,0,1,0,0,0]])
  # Hardest Puzzle  
  t = Puzzle.new([[8,0,0,0,0,0,0,0,0],[0,0,3,6,0,0,0,0,0],[0,7,0,0,9,0,2,0,0],[0,5,0,0,0,7,0,0,0],[0,0,0,0,4,5,7,0,0],[0,0,0,1,0,0,0,3,0],[0,0,1,0,0,0,0,6,8],[0,0,8,5,0,0,0,1,0],[0,9,0,0,0,0,4,0,0]])
=end
