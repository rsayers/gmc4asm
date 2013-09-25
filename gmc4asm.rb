#!/usr/bin/env ruby

def usage
  puts "Usage:\n\n#{__FILE__} [OPTIONS] src.asm\n"
  puts "Options:\n"
  puts "\t-h Help: Display this message"
  puts "\t-l LED Output: Display hex values along with the GMC4 Led indicators"
  puts "\t-a ASM Output (Default): Display Text addresses, hex values, and original assembly code\n"
end

if ARGV[0].nil? then
  usage
  exit
end

runmode = :asm

# We expect no args other than fielname at first
filename = ARGV[0]
if ARGV[0][0]=="-" && ARGV[0].length==2 then
  filename = ARGV[1]
  case ARGV[0]
    when "-h"
    usage
    exit
  when "-l"
    runmode = :led
  when "-a"
    runmode = :asm
  else
    puts "Invalid switch: #{ARGV[0]}\n"
    usage
    exit
  end
end

if filename.nil? then
  usage
  exit
end

if (!File.exist?(filename)) then
  puts "File not found: #{filename}"
  usage
  exit
end

src = open(filename).read

lines = src.split("\n")


instructions = {}
instructions["KA"] = {"ins"=>"0","operands"=>0};
instructions["AO"] = {"ins"=>"1","operands"=>0};
instructions["CH"] = {"ins"=>"2","operands"=>0};
instructions["CY"] = {"ins"=>"3","operands"=>0};
instructions["AM"] = {"ins"=>"4","operands"=>0};
instructions["MA"] = {"ins"=>"5","operands"=>0};
instructions["M+"] = {"ins"=>"6","operands"=>0};
instructions["M-"] = {"ins"=>"7","operands"=>0};
instructions["TIA"] = {"ins"=>"8","operands"=>1};
instructions["AIA"] = {"ins"=>"9","operands"=>1};
instructions["TIY"] = {"ins"=>"A","operands"=>1};
instructions["AIY"] = {"ins"=>"B","operands"=>1};
instructions["CIA"] = {"ins"=>"C","operands"=>1};
instructions["CIY"] = {"ins"=>"D","operands"=>1};
instructions["JUMP"] = {"ins"=>"F","operands"=>2};
instructions["CAL"] = {"ins"=>"E","operands"=>1};

functions = {}
functions["RSTO"]="0"
functions["SETR"]="1"
functions["RSTR"]="2"
functions["CMPL"]="4"
functions["CHNG"]="5"
functions["SIFT"]="6"
functions["ENDS"]="7"
functions["ERRS"]="8"
functions["SHTS"]="9"
functions["LONS"]="A"
functions["SUND"]="B"
functions["TIMR"]="C"
functions["DSPR"]="D"
functions["DEM-"]="E"
functions["DEM+"]="F"

# first pass, lets remove comments and extra whitespace
lines = lines.map{ |l|
  line = l.split(";")[0]
  line.strip! if !line.nil?
  line
}

# let's delete nils and blank lines

lines = lines.delete_if{ |l|
  l==nil || l==""
}

# Star address,  this will be incremented as we read instructions in order to determine the addresses of labels
addr = 0
# This hash will keep the labels and addresses together
labels = {}
# The final assembled code is stored here
output = []

lines.each do |l|

  # Upcase everything so we dont run into issues with string matches later
  l.upcase!

  # get the label and save its location
  if l.match(":") then
    label,l=l.split(":")
    # Store the hex of the jump address in the labels hash
    labels[label]=addr.to_s(16).rjust(2,'0').upcase
    # add the label to the output, simply for readability later on
    output << {"orig"=>label}
  end

  # if the label was on a line by itself, l should be nil, jump to the next line
  next if l.nil?

  
  # setup our hash for this line, as store the assembly in 'orig'
  line={'orig'=>'','hex'=>[],'jump'=>nil}
  line["orig"]=l

  # split the line by whitespace, the first element will be the opcode
  ops = l.split(/\s/)
  opcode = ops.shift
  ins = instructions[opcode]
  

  # if no instructions match, error and exit
  if ins.nil? then
    puts "Unknown instruction: #{ops[0]}"
    exit!
  end


  # Make sure each opcode gets the correct number of operands.  Jump is a special case
  # because it takes 2, but in code it looks like one
  expected_operands = ins["operands"]
  if opcode=="JUMP" then
    expected_operands = 1
  end
  
  if ops.length != expected_operands  then
    puts "Bad number of operands for #{opcode}, expected #{expected_operands}, got #{ops.length}"
    exit!
  end
  
  # Save the Hex value of this opcode
  line["hex"] << ins['ins']
  
  
  if opcode=="JUMP"
    line["jump"]=ops[0]
  elsif opcode=="CAL"
    if functions[ops[0]].nil? then
      # if call is sent something invalid, error out
      puts "Not a valid function: #{ops[0]}"
      exit;
    else
      # Otherwise push the hex value 
      line["hex"] << functions[ops[0]]
    end
  else
    # If we got here, just push the rest of the operands
    ops.each do |o|
      line["hex"] << o
    end
  end

  #  Increase our address by 1 for each opcode, and by 1 more for each operand
  addr += 1 + ins["operands"]
  output << line
end


#Now to output!



#reset the address to 0
addr = 0
output.each do |ins|
  # if we have a jump defined, resolve that now
  if !ins["jump"].nil? then
    if labels[ins["jump"]].nil? then
      puts "Unknown label: #{ins["jump"]}"
      exit;
    end
    ins["hex"] = ins["hex"].concat(labels[ins["jump"]].split(''))
  end
  # if hex is nil, then we have a label, display that here
  if ins["hex"].nil? then
    print "\t" 
    print "\t" if runmode == :led
    puts ins["orig"] + ":"
  else
    # otherwise, list the address, hex value, and assembly code here
    if runmode == :asm then
      puts addr.to_s(16).upcase.rjust(2,'0') + ": " + ins["hex"].join(' ')  + "\t\t" + ins["orig"]
      addr += ins["hex"].length
    else
      firstcode = true
      ins["hex"].each do |h|
        puts addr.to_s(2).rjust(7,'0').gsub("1","*").gsub("0","-")+"\t " + h + ( firstcode ? "\t" + ins["orig"] : "")
        firstcode = false
        addr+=1
      end
    end
    
  end
end
