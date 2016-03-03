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
	url = 'http://www.worstroom.com/'
	page = scraper.get(url)

	results = []

	# tags = []

	# that = scraper.get(BASE_URL).search('a.tag').map { |tag|
	# 	binding.pry
	# 	tags << [tag.text]
	# }

	# intializes another_page and page_num variables
	another_page = true
	page_num = 2

	total = 0

	while another_page == true
		postings = page.search('li.post').map { |li| 
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
				if (image_el = li.search('div.content div.photo img')).length > 0
					image = image_el.attr("src").value
				end 
				# grabs the string caption of image
				if (full_caption = li.search('div.content div.caption').text).length > 0
					# grabs price for rental 
					price = full_caption.match('([£$€])(\d+(?:\.\d{2})?)').to_s
					# gets long, unformated, dirty text
					caption_text_long = full_caption.split(".00")[1] || ""
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
				end
				# grab a random number between 1 and 10 for the number of ppl that can rent a room
				accomodates = rand(1..10)
				# skip if  
				if Listing.find_by( photo_url: image ) == nil && location != nil && location != '' && reformatted_caption != ''
					puts "inserted result: #{image}"
					results << ["date": date, "image": image, "caption": reformatted_caption, "location": location, "price": price, "accomodates": accomodates]
				else
					puts "skipped result: #{image}"
				end
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
				if Listing.find_by( photo_url: x[:photo_url] ) == nil
					listing = Listing.create(date_posted: date_posted, location: location, photo_url: photo_url, description: description, price: price, accommodates_num: accomodates)
					id = listing.id
					scraper.get(photo_url).save "public/listing_images/#{id}.jpg" 
				end
			end
		end


		puts "saved #{results.length}"
		total += results.length


		check_back_link = page.search('body div#footer div#pagination p.back a')
		if check_back_link.any?
			page = scraper.get("http://www.worstroom.com/page/#{page_num}")
			puts "http://www.worstroom.com/page/#{page_num}"
			page_num += 1
			results = []
		else
			another_page = false
		end
	end
	puts "saved total: #{total}"

end

