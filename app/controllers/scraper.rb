require "mechanize"
require "pry"

scraper = Mechanize.new
# That history_added line is a callback, 
# a method that runs every time you finish visiting a new page. 
# What it's doing is rate limiting your scraping, so that you 
# stop and wait half a second between each time you visit a page.
# Otherwise sites may block you.
scraper.history_added = Proc.new { sleep 0.5 }
BASE_URL = scraper.get('http://www.worstroom.com/')

results = []

tags = []

# that = scraper.get(BASE_URL).search('a.tag').map { |tag|
# 	binding.pry
# 	tags << [tag.text]
# }

binding.pry
this = scraper.get(BASE_URL).search('li.post').map { |li|
	date = li.search('div.meta h2 a').text
	# image = li.search('div.content div.photo a img').attr("src").value
	caption = li.search('div.content div.caption').text
	binding.pry
	results << ["date": date, "caption": caption]
}


# binding.pry
# scraper.get(BASE_URL) do |search_page|
# 	# search_page.each do |listing|
# 	# 	listing.search("ol.posts").text
# 	# 	binding.pry
# 	# end


#     listing = search_page.search("ol").text
#     binding.pry
#     new_listing = []
#     results << [new_listing]
#     binding.pry
# end