
require 'json'
require 'set'


## scratch code to perform initial investigation of the generated compile commands
## was curious about
##   total number of files
##   common includes
##   common defines
##   possibility of grouping files based on the compiler args


def grouping_key(args)
  s = [].to_set
  args.each do |a|
    if a=~/^-I/ or a=~/^-D/
      s.add a
    end
  end
  s
end

def count_all(commands)
  h = {}
  h.default = 0
  commands.each do |c|
    grouping_key(c["arguments"]).each do |k|
      h[k] = h[k]+1
    end
  end
  h
end

def intersect_all(commands)
  h = [].to_set
  commands.each do |c|
    h = h & grouping_key(c["arguments"])
  end
  h
end

data = JSON.parse(File.read('compile_commands.json'))




all = count_all data

important = all.select{|k,v| v > 2000}.sort_by {|k,v| v}.reverse
important.each {|k,v| puts "#{k}->#{v}"}

imp = [].to_set
important.each {|k,v| imp.add(k)}

class Set
  def to_s
    to_a.join(', ')
  end
end

puts imp


def important_grouping_key(args, imp)
  s = [].to_set
  args.each do |a|
    if a=~/^-I/ or a=~/^-D/ and imp.member? a
      s.add a
    end
  end
  s
end

puts (important_grouping_key(data[0]["arguments"], imp))

def group_all(commands, imp)
  h = {}
  h.default=0
  commands.each do |c|
    k=important_grouping_key(c["arguments"], imp)
    h[k]=h[k]+1
  end
  h
end

puts "results"
g = group_all data, imp
g.each do |k,v|
  puts "#{v} #{k}"
end

##############################

js = data
dirs = [].to_set
js.each {|j| dirs.add j["directory"]}

puts js.size
puts dirs

js.each do |j|
  args = j["arguments"]
  abort "not cc: #{args}" unless args[0].eql? "cc"
  abort "not -c: #{args}" unless args[1].eql? "-c" or args[1].eql? "-S"
  abort "not -o: #{args}" unless args[-3].eql? "-o"
  abort "not file: #{args}" unless args[-1].eql? j["file"]
end
escaped_quote='\\' * 3 + '"'
puts escaped_quote
puts (js[0]["arguments"].join ' ').gsub(/"/, escaped_quote)
