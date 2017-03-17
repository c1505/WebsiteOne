require 'spec_helper'

RSpec.describe Recurrence do
  before(:each) do
    ENV['TZ'] = 'UTC'
  end

  after(:each) do
    Delorean.back_to_the_present
  end
  
  describe "#next_occurrences" do
    it "returns one next occurrence on correct day and time" do
      Delorean.time_travel_to(Time.parse('2017-03-09 08:00:01 UTC'))
      event = FactoryGirl.build_stubbed(:repeating_forever_event)
      recurrence = Recurrence.new(event)
      binding.pry
      expect(recurrence.next_occurrences.first[:time]).to eq Time.parse("Sun, 12 Mar 2017 23:30:00 UTC +00:00") 
    end
    
    it "does not return persisted occurrence"
    # if an occurence is the persisted one, it is not returned as it is covered
    #  by the regular query in events
  end
end