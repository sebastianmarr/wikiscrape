require "rubygems"
require "mechanize"
require "sanitize"
require "iconv"
require "benchmark"
require "algorithms"

class WikipediaScraper

  def initialize
    @visited_links = Containers::RBTreeMap.new
    @queue = Queue.new
  end

  def run(start)

    file = File.new("./wiki.txt", "w")

    # set user agent to safari or wikipedia will not let you in
    agent = Mechanize.new do |a|
      a.user_agent_alias = 'Mac Safari'
      a.max_history = 0
    end

    start_page = agent.get(start)
    enqueue_links start_page

    while !@queue.empty?
      begin
        page = @queue.deq.click
        file.puts extract_text(page)
        if (@queue.size < 100)
          enqueue_links(page)
        end
      rescue Mechanize::ResponseCodeError
      end
    end

    file.close
  end

  def extract_text(page)
    puts page.title.chomp!(" - Wikipedia, the free encyclopedia")
    Iconv.conv('ASCII//IGNORE', 'UTF8', 
    Sanitize.clean(page.search("div#bodyContent //p").to_s))
  end

  def enqueue_links(page)
    page.links_with(:href => /\A\/wiki\/[^:]*\z/).each do |link|
      unless @visited_links.has_key?(link.uri.to_s)
        @visited_links[link.uri.to_s] = true
        @queue.enq link
      end
    end
  end
end

w = WikipediaScraper.new
w.run("http://en.wikipedia.org")
