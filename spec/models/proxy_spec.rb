require File.expand_path('../../spec_helper', __FILE__)

module RestAssured::Models
  describe Proxy do
    it { should validate_presence_of(:to) }
    it { should allow_mass_assignment_of(:to) }
  end
end
