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
					# sets path for the original image and file name
					# use double quotes - single quotes don't work for string interpolation
					original_image_path = Rails.root.join('public','listing_images',"#{id}.original.jpg")
					default_image_path = Rails.root.join('public','listing_images',"#{id}.jpg")
					thumbnail_image_path = Rails.root.join('public','listing_images',"#{id}.thumb.jpg")
					# saves image locally to public images folder
					scraper.get(photo_url).save(original_image_path)
					# using MiniMagick for image resizing
					original = MiniMagick::Image.open(original_image_path)
					default = original.resize('300x400')


					# resize_w_crop minimagick approach by maxicak https://gist.github.com/maxivak/3924976

					def resize_with_crop(img, w, h, options = {})
					    gravity = options[:gravity] || :center

					    w_original, h_original = [img[:width].to_f, img[:height].to_f]

					    op_resize = ''

					    # check proportions
					    if w_original * h < h_original * w
					      op_resize = "#{w.to_i}x"
					      w_result = w
					      h_result = (h_original * w / w_original)
					    else
					      op_resize = "x#{h.to_i}"
					      w_result = (w_original * h / h_original)
					      h_result = h
					    end

					    w_offset, h_offset = crop_offsets_by_gravity(gravity, [w_result, h_result], [ w, h])

					    img.combine_options do |i|
					      i.resize(op_resize)
					      i.gravity(gravity)
					      i.crop "#{w.to_i}x#{h.to_i}+#{w_offset}+#{h_offset}!"
					    end

					    img
					  end

					  # from http://www.dweebd.com/ruby/resizing-and-cropping-images-to-fixed-dimensions/

					  GRAVITY_TYPES = [ :north_west, :north, :north_east, :east, :south_east, :south, :south_west, :west, :center ]

					  def crop_offsets_by_gravity(gravity, original_dimensions, cropped_dimensions)
					    raise(ArgumentError, "Gravity must be one of #{GRAVITY_TYPES.inspect}") unless GRAVITY_TYPES.include?(gravity.to_sym)
					    raise(ArgumentError, "Original dimensions must be supplied as a [ width, height ] array") unless original_dimensions.kind_of?(Enumerable) && original_dimensions.size == 2
					    raise(ArgumentError, "Cropped dimensions must be supplied as a [ width, height ] array") unless cropped_dimensions.kind_of?(Enumerable) && cropped_dimensions.size == 2

					    original_width, original_height = original_dimensions
					    cropped_width, cropped_height = cropped_dimensions

					    vertical_offset = case gravity
					      when :north_west, :north, :north_east then 0
					      when :center, :east, :west then [ ((original_height - cropped_height) / 2.0).to_i, 0 ].max
					      when :south_west, :south, :south_east then (original_height - cropped_height).to_i
					    end

					    horizontal_offset = case gravity
					      when :north_west, :west, :south_west then 0
					      when :center, :north, :south then [ ((original_width - cropped_width) / 2.0).to_i, 0 ].max
					      when :north_east, :east, :south_east then (original_width - cropped_width).to_i
					    end

					    return [ horizontal_offset, vertical_offset ]
					  end

					default_crop = resize_with_crop(default, 300, 400)


					# default_crop = default.crop('225x200+0+0')
					# default_crop.write(default_image_path)
					default_crop.write(default_image_path)
					
					thumb = original.resize('100x100')
					thumb_crop = resize_with_crop(thumb, 100, 100)
					thumb_crop.write(thumbnail_image_path)
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

