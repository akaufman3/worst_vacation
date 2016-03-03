class MainController < ApplicationController
 	def home
 		@last_eight = Listing.all.slice(-8, 8)
 		render:home
 	end

end