class User < ActiveRecord::Base
	has_secure_password

	before_save { self.email = email.downcase }
	validates :fname,  presence: true, length: { maximum: 50 }
	validates :lname,  presence: true, length: { maximum: 50 }
	VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  	validates :email, presence: true, length: { maximum: 255 }, format: { with: VALID_EMAIL_REGEX }, uniqueness: { case_sensitive: false }
end
