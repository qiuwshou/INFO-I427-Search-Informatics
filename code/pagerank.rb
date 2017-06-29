#!/usr/bin/ruby
#this program only run once!!!!


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

#index= {doc_id => url}
#adj_matrix = {doc_id => [outbound_links]}

def build_matrix(adj_matrix, index)
  new_matrix = {} 
  list =[]
  adj_matrix.each_key do |key|
    list.push(key)
  end 

  adj_matrix.each_key do |key|
    links = adj_matrix[key]
    links.delete_if {|link| index.has_value?(link) == false}
    links.each {|link| links[links.index(link)] = index.key(link)}
    if links.size == 0
      links = list.delete(key)
    end
    if links.is_a?(String)
      links = [links]
    end       
    links.uniq!
    new_matrix[key] = links   
  end 
  return new_matrix
end

def page_rank(adj_matrix, iteration, size)
  damping_factor = 0.85
  page_rank = Hash.new(1.0/size) 
  count = 0
  inter_page_rank = Hash.new(0)  
  sum = 0 

#inbound link = i, outbound link = j
  while count <= iteration do
    adj_matrix.each_key do |i|
      outbound_links = adj_matrix[i]
      degree = outbound_links.size
      if degree >  0
        #probability of jumping from i to j
        outbound_links.each do |j|
          inter_page_rank[j] +=  page_rank[i]/degree
          end 
      else
        
      end     
    end
    adj_matrix.each_key do |page|
      page_rank[page] = (damping_factor*inter_page_rank[page] + (1-damping_factor)/size).round(5)
      inter_page_rank[page] = 0
    end
    count += 1
  end 
  return page_rank
end

file_list = Dir.entries("html/")
file_list.sort!
file_list = file_list[2..-1]
size = file_list.size

index = read_data("index.dat")
adj_matrix = read_data("adj_matrix.dat")

adj_matrix = build_matrix(adj_matrix, index)
result = page_rank(adj_matrix, 20, size)
result.to_s
write_data("pagerank.dat", result)
