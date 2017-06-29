#!/usr/bin/ruby
# This crawler only run once!!!!!!!!!
# topic is food, crawl 6000 links and save them.
require 'nokogiri'
require 'rubygems'
require 'open-uri'


seed_url = "http://en.wikipedia.org/wiki/List_of_cuisines"
#return the content of a page
 # page = Nokogiri::HTML(open(html, 'User-Agent' => user_agent), nil, "UTF-8")

#---------------crawler---------------
#find all the links on one page
def find_links(url)
  begin
  html_code = Nokogiri::HTML(open(url, 'User-Agent'=> 'IUB-I427-qiuwshou'))
  base_url = url[/^.+?[^\/:](?=[?\/]|$)/]
  outbound_links = []
  href = html_code.css("a")
  href.each do |h|
    h = h.attribute('href').to_s
    #if it is a local link then add base_url to it
    if h =~ /https?:\/\/(.+)/
      outbound_links.push(h)
    else
      outbound_links.push(base_url+h)
    end
  end
  rescue
    puts "#{url} can't be open"
  end
  return outbound_links
end

def bfs(url, visited_list)
  visited_list += find_links(url)
  parent_link = [url]
  while visited_list.size <= 5000  do
    child_link = []
    parent_link.each do |parent|
      if find_links(parent) != nil
        child_link = child_link +  find_links(parent)
        child_link.uniq!
        child_link.compact!
      end
    end
    if child_link.size > 0
      visited_list = visited_list + child_link
      parent_link = child_link
      visited_list.uniq!
    else 
      break
    end
  end
  visited_list.uniq!
  return visited_list[0..4999]
end


#take a list of urls, rename them and save the content.
#use a index.dat to save the urls and save all the content of url under one dire\
def save_file(url_list)
  Dir.mkdir("html")
  index = {}
  file2 = File.open("index.dat","w")
  url_list.each do |url|
    begin
    filename =  url_list.index(url).to_s+".html" 
    html_code = Nokogiri::HTML(open(url, 'User-Agent'=> 'IUB-I427-qiuwshou'))
    index[filename] = url 
    file = File.open(Dir.pwd+"/html/"+filename, "w")
    file.print(html_code)
    file.close
    rescue 
      puts "#{url} is not accessable"     
    end
    end
  file2.close
  return index
end

def write_data(filename, data)
  file = File.open(filename, "w")
  file.puts(data)
  file.close
end


links = bfs(seed_url, [])

puts "start crawling"
index = save_file(links)
write_data("index.dat", index.to_s)
puts "crawling finished"
