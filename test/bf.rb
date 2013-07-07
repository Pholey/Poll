#!/usr/bin/env ruby

class BrainFuck
  def initialize
    @tray = create_ops
    @seg = Array.new(1024,0)
    @tp = 0
    @res = []
    @cop = 0
  end

  def bundle c
    c.split("").each do |o|
      if @tray.has_key? o
        @res << o
      end
    end
    return self
  end

  def start args
    bundle(args)
    while @cop < @res.size
      run_op @res[@cop]
    end
    @cop = 0
  end

  private

  def run_op op
    @tray[op].call
    @cop += 1
  end

  def get_input
    @seg[@tp] = STDIN.getc
    # getc returns nil on EOF. We want to use 0 instead.
    @seg[@tp] = 0 unless @seg[@tp]
  end

  def create_ops
    { ">" => Proc.new { @tp = (@tp == @seg.size - 1 ? 0 : @tp + 1) },
      "<" => Proc.new { @tp = (@tp == 0 ? @seg.size - 1 : @tp - 1) },
      "+" => Proc.new { @seg[@tp] += 1 },
      "-" => Proc.new { @seg[@tp] -= 1 },
      "." => Proc.new { print @seg[@tp].chr if @seg[@tp] },
      "," => Proc.new { get_input },
      "[" => Proc.new { jump_to_close if @seg[@tp] == 0 },
      "]" => Proc.new { jump_to_open unless @seg[@tp] == 0 }
    }
  end

  def jump_to_close
    level = 1
    while @cop < @res.size
      @cop += 1
      if @res[@cop] == '['
        level += 1
      elsif @res[@cop] == ']'
        level -= 1
      end
      break if level == 0
    end
  end

  def jump_to_open
    level = 1
    while @cop >= 0
      @cop -= 1
      if @res[@cop] == ']'
        level += 1
      elsif @res[@cop] == '['
        level -= 1
      end
      break if level == 0
    end
  end
end

args = ARGV.slice(0 ..-1).join(" ")
app =  BrainFuck.new
app.start(args)

