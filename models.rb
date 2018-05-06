class User < ActiveRecord::Base
    has_many :posts
    has_many :pokemon
end

class Post < ActiveRecord::Base
    belongs_to :user
end

class Pokemon < ActiveRecord::Base
    belongs_to :user
end
