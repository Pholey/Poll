#!/usr/bin/env ruby

module BrainRuck

  class Code
    def initialize
      text = Interpreter.new
    end
    
    def fuckify(string)    #for submitting pure brainfuck code in
      return vote.start(string)
    end

    def ruckify(string)
      return vote.start(string)
    end
  end

  class Interpreter

    def initialize
      @tray = create_ops
      @seg = Array.new(1024, 0)
      @tp = 0
      @res = []
      @cop = 0
    end

    # create_ops
    def create_ops
      {
        ">" => -> { @tp = (@tp + 1) % @seg.size },
        "<" => -> { @tp = (@tp - 1) % @seg.size },
        "+" => -> { @seg[@tp] += 1 },
        "-" => -> { @seg[@tp] -= 1 },
        "." => -> { @upstream << @seg[@tp].chr if @seg[@tp] },
        "," => -> { get_input },
        "[" => -> { jump_to_close if @seg[@tp] == 0 },
        "]" => -> { jump_to_open unless @seg[@tp] == 0 }
      }
    end


    ##
    # stopwatch
    #   not really necassary to the operation of the class, only a benchmark
    #   helper
    def stopwatch
      now = Time.now
      yield
      return Time.now - now
    end
    def stopwatch_s(&block)
      f = stopwatch(&block)
      "%f sec(s)" % f
    end

    ##
    # bundle(String str)
    #   compiles string as a brainfuck code
    def bundle(str)
      str.split("").each do |c|
        if @tray.has_key?(c) # is this a valid command?
          @res << c # add to stack
        end
      end
      return self
    end

    ##
    # start(Array<String> args)
    def start(args)
      bundle(args)
      # instead of printing the characters, they are pushed unto this string
      @upstream = ""
      @cop = 0 # reset index
      while @cop < @res.size
        con_op(@res[@cop])
      end
      return @upstream
    end

    ##
    # main(Array<String> args)
    def main(args)
      argv = args.dup # to safetly handle this array without breakage
      if argv.empty?
        system 'clear'
        puts "Brainfuck 1.0.2\n\n"
        begin
          while true
            print "++> "
            bf_input = gets.chomp
            print "=+> "
            code = ""
            s = stopwatch_s do
              code = start(bf_input)
            end
            puts code
            puts "executed in %s" % s
          end
        rescue Interrupt
          puts "\nexiting."
        end
      end
      while(arg = argv.shift)
        case arg
        ## reads the next argument as a brainfuck string
        when "-i", "--interpret"
          puts start(argv.shift)
        ## read file
        when "-d", "--decode"
          filename = argv.shift
          file = File.read(filename)
          puts start(file)
        ## compiles next arg as a brainfuck string
        when "-e", "--encode"
          filename = argv.shift
          data = File.read(filename)
          puts brainfuckify(data)
        ## compiles next arg as a brainfuck string
        when "-c", "--compile"
          puts brainfuckify(argv.shift)
        ## read as ruby program
        when "-r", "--to-rb" # read ruby file
          filename = argv.shift
          #puts "[BF] reading %s from brainfuck as ruby program" % filename
          bf = File.read(filename)
          code = ""
          s = stopwatch_s do
            code = start(bf)
          end
          puts "Compiled in %s" % s
          puts eval(code)
        when "-h", "--help"
          puts help
        else
          filename = arg
          puts filename.to_s
          bf = File.read(filename)
          code = ""
          code = start(bf)
          puts code
        end
      end
    end

  private

    ##
    # con_op(op_code)
    #   executes the command from the op_code
    def con_op(op_code)
      @tray[op_code].call
      @cop += 1
    end

    ##
    # get_input
    def get_input
      @seg[@tp] = STDIN.getc
      # getc returns nil on EOF. We want to use 0 instead.
      @seg[@tp] = 0 unless @seg[@tp]
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

    ##
    # tobf(char char)
    #   converts character to Brainfuck string
    def tobf(char)
      brainfuck = ""
      to_ord = char.ord
      div = to_ord / 10
      mod = to_ord % 10

      brainfuck += "%s\n" % ("+" * 10)
      brainfuck += "[\n"
      brainfuck += "  >\n"
      brainfuck += "  %s\n" % ("+" * div)
      brainfuck += "  <\n"
      brainfuck += "  -\n"
      brainfuck += "]\n"
      brainfuck += ">\n"
      brainfuck += "%s\n" % ("+" * mod)
      brainfuck += ".\n"
      brainfuck += "[-]\n"
      return brainfuck
    end

    ##
    # brainfuckify(String string)
    #   compiles string as brainfuck
    def brainfuckify(string)
      brainfuck = ""
      for char in string.split("")
        brainfuck += tobf(char)
      end
      return brainfuck.gsub(" ", "").gsub("\n", "")
    end

    ##
    # help
    #   yeah its a help function
    def help
      puts "Usage: ./brainfuck [OPTIONS] STRING"
      puts "Options:"
      puts "  -h --help               displays this help message."
      puts "  -c --compile <string>   converts plain text to brainfuck and prints to console"
      puts "  -e --encode <filename>  reads next argument as a file and encodes as brainfuck"
      puts "  -r --to-rb <file>       reads brainfuck from file and runs as a ruby program"
      puts "  -d --decode <filename>  reads next argument as a file and prints the decoded\n" +
           "                          brainfuck to console"
      puts "  -i --interpret <string> reads next argument as a brainfuck string and\n" +
           "                          prints to console"
    end

    ##
    # run(Array<String> argv)
    #   fatest way from your console to ruby
    def self.run(argv)
      new.main(argv)
    end

  end
end

argv = ARGV
BrainRuck::Interpreter.run(argv)

