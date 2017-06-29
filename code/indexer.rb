#!/usr/bin/ruby
#only ruby this file once!!!!!!!!!!!
#build invindex.dat and docindex.dat
require 'nokogiri'
require 'rubygems'
require 'open-uri'
require 'fast-stemmer'


#take a list of urls, rename them and save the content.
#use a index.dat to save the urls and save all the content of url under one diretory


#-----------functions for index-------
def read_data(file_name)
  file = File.open(file_name,"r")
  object = eval(file.gets)
  file.close()
  return object
end


def write_data(filename, data)
  file = File.open(filename, "w")
  file.puts(data)
  file.close
end

def load_stopwords_file(filename) 
  stopwords = []
  file = File.open(filename, "r")
  words = file.readlines
  words.each do |w|
    stopwords.push(w)
  end
  return stopwords
end

def remove_stop_tokens(tokens, stop_words)
  temp = tokens
  temp.each do |w|
    if stop_words.include?(w) == true
      tokens.delete(w)
    end
  end   
  return tokens
end

def find_links(doc_name, source_url)
  html_code = Nokogiri::HTML(open("html/"+doc_name))
  #find base of source_url
  base_url = source_url[/^.+?[^\/:](?=[?\/]|$)/]
  outbound_links = []
  href = html_code.css("a")
  href.each do |h|
    h = h.attribute('href').to_s
  #if it is a local link then add base_url to it
    if h["href"] =~ /https?:\/\/(.+)/ 
      outbound_links.push(h)
    else 

      outbound_links.push(base_url+h)
    end
  end 
  return outbound_links
end

def find_tokens(filename,directory)
  filename = directory + filename
  myfile = File.open(filename, "r")
  lines = myfile.readlines
  word_list = []
  lines.each do |line|
    #clear the invalid utf-8 character and split word
    line =  line.encode('UTF-8', :invalid=>:replace, :undef => :replace)
    #remove the punctuation and replace by white space
    line = line.downcase.gsub(/[^[[:word:]]\s]/, ' ') 
  # convert to downcase
    line = line.downcase.gsub(/[^a-z0-9]\s/, '')
    words = line.split(/[ ,\-]/)
    words.each do |w|
      word_list.push(w)
    end
  end
  myfile.close()
  new_list = []
  word_list.each do |word|
    #  word = word.delete("<>()[]{}\\-*_&^%$#@!~`':\\\\|;\"?/., \t") 
    new_list.push(word) if ! (word =~ /^$/)
  end
  return new_list
end

def stem_tokens(tokens)
  new_list = []
  #use fast-stemmer to get the stem of token
  tokens.each {|token| new_list.push(token.stem)}
  return new_list
end
#------------------
def read_file_into_list(filename)
  myfile = File.open(filename, "r")
  lines = myfile.readlines
  word_list = []
  lines.each do |line|
    words = line.encode('UTF-8', :invalid=>:replace).split(/[ ,\-]/)
    words.each  { |w|  word_list.push(w) }
  end

  myfile.close()
 
  return word_list
end

def clean_string_list(word_list)

  new_list = []
  word_list.each do |word|
    new_word = word.delete("<>()[]{}\\-*&^%$#@!~`':\\\\|;\"?/., \t").downcase.chomp
    new_list.push(new_word) if ! (new_word =~ /^$/)
  end
  
  return new_list
end

def count_word(word_list)
   new_list = Hash.new
   word_list.each do |word|   
       if new_list.has_key?(word) == true
          new_list[word] = new_list[word] + 1
       else
          new_list[word] = 1
       end
   end
   return new_list
end

def get_score(test_file, spam_list, nonspam_list)

   score = 0

   test_file.each do |word|
      if spam_list.has_key?(word) == true
         log_S = Math.log(spam_list[word])
      else
         log_S = 0
      end

      if nonspam_list.has_key?(word) == true
         log_N = Math.log(nonspam_list[word])
      else
         log_N = 0
      end

      score = score + log_S - log_N
  end
   
  return score 
  # if score >= 0
  #   puts "Document is a spam"
  # else
  #    puts "Document is not a spam"
  # end

end
#-------------------main function-----------
stop_words = load_stopwords_file("stop.txt")

spam_list = clean_string_list(read_file_into_list("known_spam.txt"))
spamwords = count_word(spam_list)
nonspam_list = clean_string_list(read_file_into_list("known_notspam.txt"))
nonspamwords = count_word(nonspam_list)


index = read_data("index.dat")
invindex = {}
docindex = {}
adj_matrix = {}

file_list = Dir.entries("html")
file_list.sort!
file_list = file_list[2..-1]

puts"indexing!!!!!"

# scan through the documents one-by-one
file_list.each do |doc_name|
  source_url = index[doc_name]
  tokens = find_tokens(doc_name,"html/")
  tokens = remove_stop_tokens(tokens, stop_words)
  tokens = stem_tokens(tokens)
   
  score = get_score(tokens,spamwords, nonspamwords)  
#---------update the information for inverted index file
  ##invindex = {token=>[df,{page => tf, page2 => tf2....}]} 
  tokens.each do |token|
    if invindex.has_key?(token) == false
      links = {}
      links[doc_name] = 1
      invindex[token] = [1, links]
    else 
      links = invindex[token][1]
      df = invindex[token][0] + 1
      tf = links[doc_name]
      if tf == nil 
        tf = 1
      else 
        tf += 1
      end
      links[doc_name] = tf
      invindex[token] = [df, links]
      links = {}
    end
  end
#----------update the information for docment index
  #docindex = {page =>[document_length: =>, Title:=>,  Url Name:=>}
  page = Nokogiri::HTML(open("html/"+doc_name))
  outbound_links = find_links(doc_name, source_url)
  adj_matrix[doc_name] = outbound_links
  if outbound_links.length != 0
     dl = tokens.size
     if page.css("title")[0] == nil
       t = "This page has no title."
     else
       t = page.css("title")[0].text
     end
    docindex[doc_name] = {"length"=>dl,"title"=>t,"url"=>source_url,"spam-score"=>score }
  end
end

puts "writing invindex"
write_data("invindex.dat", invindex.to_s)
puts "writing doc"
write_data("docindex.dat", docindex.to_s)
puts "writing adj_matrix"
write_data("adj_matrix.dat", adj_matrix.to_s)
