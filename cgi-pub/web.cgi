#!/l/ruby-2.1.0/bin/ruby
# encoding: utf-8
require 'cgi'
require 'rubygems'
require 'fast-stemmer'


cgi = CGI.new("html4")

def read_data(file_name)
  file = File.open(file_name,"r:UTF-8")
  object = eval(file.gets)
  file.close()
  return object
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
    tf_idf[page] = total_tfidf
    total_tfidf = 0
    end      
  end 
  #sort hash by value 
  tf_idf.sort {|a, b| a[1] <=> b[1]}
  return tf_idf
end

#??????????????????????
def combine(tfidf, pagerank,docindex)
  score = {}
  pagerank.each do |k, v|
    #combine tfidf with pagerank
    if tfidf[k] != nil
      v = ((Math.log(tfidf[k]))*v ).round(5)
      score[k] = v
    end
  end
  #sort the final score and 
  sort_score =Hash[score.sort_by{|k, v| v}.reverse]
  count = 0
  page = []
  sort_score.each_key do |k|
    if count < 100
     # page[k]={"title"=> docindex[k]["title"],"url"=>docindex[k]["url"]}
      page.push( [docindex[k]["url"],docindex[k]["title"]])
    end
    count += 1
  end
  return page
end



index = read_data("index.dat")
invindex = read_data("invindex.dat")
docindex = read_data("docindex.dat")
page_rank = read_data("pagerank.dat")


keyword_list = cgi['Query'].to_s
keyword_list = keyword_list.split
query_list = stem(keyword_list)
hit_list = find_hits(query_list, invindex)
tfidf = tf_idf(query_list, hit_list, invindex, docindex)
links = combine(tfidf,page_rank,docindex)



cgi.out{
cgi.html{
  cgi.head{ "\n"+cgi.title{"My page title"} } +
  cgi.body{ "\n"+cgi.h1{"Amazing cat finds something for you!"} +
      "The query word you searched:" + cgi['Query'] + 
      links.reduce(""){ |s,a|    link,text = a;    s+"<p><a href="+link+">"+text+"</a\></p>"}

    }
  }
}
