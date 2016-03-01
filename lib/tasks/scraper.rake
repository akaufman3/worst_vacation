require "mechanize"
require "pry"

desc "Scrapes Worstroom.com"
task :scrape => [:environment] do
	scraper = Mechanize.new
	# That history_added line is a callback, 
	# a method that runs every time you finish visiting a new page. 
	# What it's doing is rate limiting your scraping, so that you 
	# stop and wait half a second between each time you visit a page.
	# Otherwise sites may block you.
	scraper.history_added = Proc.new { sleep 0.5 }
	BASE_URL = scraper.get('http://www.worstroom.com/')

	results = []

	# tags = []

	# that = scraper.get(BASE_URL).search('a.tag').map { |tag|
	# 	binding.pry
	# 	tags << [tag.text]
	# }

	postings = scraper.get(BASE_URL).search('li.post').map { |li| 
		if li.at_css('div.video-post')
			# how do I just ignore this one?
			puts "VIDEO"
		else
			tags = []


			# how to get sibiling nodes???

			# a = li.xpath("preceding-sibling::a[1]").text
			# if a == "" 
			# 	puts "hello"
			# else 
			# 	tags << a
			# 	binding.pry
			# end
			# li.xpath('a').each_with_index do |li|
			# 	li.xpath("preceding-sibling::a[1]").text
			# 	binding.pry
			# end

			# grabs date of post
			date = li.search('div.meta h2 a').text
			# grabs image url of post
			image = li.search('div.content div.photo img').attr("src").value
			# grabs the string caption of image
			full_caption = li.search('div.content div.caption').text
			# grabs price for rental 
			price = full_caption.match('([£$€])(\d+(?:\.\d{2})?)').to_s
			# gets long, unformated, dirty text
			caption_text_long = full_caption.split(".00")[1]
			# removes extra quotes
			caption_text_remove = caption_text_long.tr('\”', '.')
			#removes extra quotes
			caption_text_remove_again = caption_text_remove.tr('“', ' ')
			# adds a space after the period
			add_period = caption_text_remove_again.gsub(/\.(?![ ])/, '. ')
			# removes extra spaces at the start and end of caption
			remove_start_end_spaces = add_period.lstrip.chop
			# ensures that every sentance starts with an uppercase letter
			make_sentences_uppercase = remove_start_end_spaces.gsub(/([a-z])((?:[^.?!]|\.(?=[a-z]))*)/i)  { $1.upcase + $2.rstrip }
			# remove any instances of a double period
			remove_double_periods = make_sentences_uppercase.gsub('. .', '.')
			# remove any new line characters
			reformatted_caption = remove_double_periods.gsub(/\n /,"")
			# get location of post
			location = full_caption.split(price)[0].lstrip.chop.gsub(".", "")
			# grab a random number between 1 and 10 for the number of ppl that can rent a room
			accomodates = rand(1..10)

			results << ["date": date, "image": image, "caption": reformatted_caption, "location": location, "price": price, "accomodates": accomodates]

		end
	}


	for i in results
		for x in i 
			date_posted = x[:date]
			location = x[:location]
			photo_url = x[:image]
			description = x[:caption]
			price = x[:price]
			accomodates = x[:accomodates]

			Listing.create(date_posted: date_posted, location: location, photo_url: photo_url, description: description, price: price, accommodates_num: accomodates)
		end
	end
end

