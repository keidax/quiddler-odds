valid_words = Set(String).new
valid_words.concat(File.read_lines("data/nwl2023_stripped.txt"))

frequent_words = [] of String
File.each_line("data/count_1w.txt") do |line|
  frequent_words << line.split("\t")[0]
end

valid_frequent_words = (frequent_words & valid_words.to_a)
File.open("data/regular_words.txt", mode: "w") do |word_file|
  word_file.puts(valid_frequent_words.first(20000).join("\n"))
end
