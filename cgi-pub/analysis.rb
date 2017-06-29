#!/usr/bin/ruby
require 'rubygems'
require 'fast-stemmer'

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


def stem(keylist)
  new_list = []
  keylist.each {|k| new_list.push(k.stem)}
  return new_list
end

def find_hits(keylists, invindex)
  hit_list = []
  keylists.each do |key|
    if invindex.has_key?(key) == true
      hits = invindex[key][1]
        hits.each_key do |k|
          if hit_list.include?(k) == false
            hit_list.push(k)
          end
        end
    end
  end           
    
  #give a exception warning if there is no document contaning any query terms
  if hit_list.size == 0
    puts "No page containing any query terms!"
  end
  #hit_list = [page1, page2,....pagen]
  return hit_list
end 

#for each query on a particular page calculate the tf-idf
def find_tfidf(query, page, invindex, doc_index)
  tf = 0
  tfidf = 0
  if invindex.has_key?(query) == true  
    tf = invindex[query][1][page]
    df = invindex[query][0] 
    doc_length = doc_index[page]["length"]  
    ntf = tf * 1.0 / doc_length
    idf = 1/(1+ Math.log(df))
    tfidf = ntf * idf
  end 
  return tfidf
end

# tf_idf = {page => tf_idf score}
def tf_idf(query_list, hit_list, invindex, doc_index)
  total_tfidf = 0
  tf_idf = Hash.new
  if hit_list.size != 0
    hit_list.each do |page|
      query_list.each do |query|
        total_tfidf += find_tfidf(query, page, invindex, doc_index)
      end
    tf_idf[page] = total_tfidf.round(5)
    total_tfidf = 0
    end      
  end 
  return tf_idf
end


def combine(tfidf, pagerank)
  result = {}
  pagerank.each do |k, v|
    v = (Math.log(tfidf[k]) * v).round(5)
    result[k] = v
  end
  sort =Hash[result.sort_by{|k, v| v}.reverse] 
  return sort 
end


#-------------main function----------
#run with ruby web.rb kw1 kw2......
#
#------------------------------------
# check that the user gave us correct command line parameters
abort "Command line should have at least 1 parameters." if ARGV.size<1


index = read_data("index.dat")
invindex = read_data("invindex.dat")
docindex = read_data("docindex.dat")
page_rank = read_data("pagerank.dat")



keyword_list = ARGV[0..ARGV.size]
query_list = stem(keyword_list)
hit_list = find_hits(query_list, invindex)
tfidf = tf_idf(query_list, hit_list, invindex, docindex)
result = combine(tfidf, page_rank)
puts result.to_s



