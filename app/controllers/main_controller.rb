class MainController < ApplicationController
 	def home
 		@listings = Listing.all
 		@last_four = Listing.all.slice(-4, 4)
 		render:home
 	end

end