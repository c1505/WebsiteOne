require 'spec_helper'

describe Recurrence, :type => :model do
  before(:each) do
    ENV['TZ'] = 'UTC'
  end

  after(:each) do
    Delorean.back_to_the_present
  end
  
end