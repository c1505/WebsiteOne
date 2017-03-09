require 'spec_helper'

RSpec.describe Recurrence do
  describe "#next_occurrences" do
    it "returns 10 events" do
      event = FactoryGirl.build_stubbed(:repeating_forever_event)
      recurrence = Recurrence.new(event)
      binding.pry
      expect(recurrence.next_occurrences.count).to eq 10
    end
  end
end