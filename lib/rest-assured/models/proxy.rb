module RestAssured
  module Models
    class Proxy < ActiveRecord::Base
      attr_accessible :to

      validates_presence_of :to
    end
  end
end
