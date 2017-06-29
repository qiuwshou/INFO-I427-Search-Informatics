#!/usr/bin/ruby
    line = "http://www.w3schools.com/html/default.asp"

  #  line = line.gsub(/\=+/, ' ')
    line = line.downcase.gsub(/[^[[:word:]]\s]/, ' ')
  print line
  # convert to downcase
  # !!!!!!!!!!!!!!!!!!!!!
    line = line.downcase.gsub(/[^a-z0-9]\s/, '')
    words = line.split(/[ ,\-]/)
  puts ''
  print words.class
  #puts line
