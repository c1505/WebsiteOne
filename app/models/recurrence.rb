class Recurrence
  attr_reader :event, :start_time, :end_time, :collection_end, :collection_start
  def initialize(event)
    @event = event
    @collection_start = Time.current - COLLECTION_TIME_PAST #this shoul also include the time not just the day i think.  
    @collection_end = Time.current + COLLECTION_TIME_FUTURE
  end
  
  include IceCube
  
  COLLECTION_TIME_FUTURE = 10.days
  COLLECTION_TIME_PAST = 300.minutes
  
  DAYS_OF_THE_WEEK = %w[monday tuesday wednesday thursday friday saturday sunday]
 
  def next_occurrences(options = {})
    schedule = IceCube::Schedule.new(collection_start_including_event_time)
    schedule.add_recurrence_rule( IceCube::Rule.weekly.day(recurring_days) )
    occurrences = schedule.occurrences(end_time)
    occurrences.map do |occurrence|
      { event: event, time: occurrence }
    end
    # only recurring events should make it here
    # repeats is currently 'weekly' and 'never'.  it should be true and false.  
  end
  #how to test this?
  
  
  private
  
  def collection_start_including_event_time
    collection_start.change( { hour: event.start_time.hour, min: event.start_time.min})
  end
  
  def end_time
    return collection_end unless event.repeat_ends_on
    if event.repeat_ends_on < collection_end
      event.repeat_ends_on
    else
      collection_end
    end
  end
  
  def recurring_days
    DAYS_OF_THE_WEEK.reject do |r|
      ((event.repeats_weekly_each_days_of_the_week_mask || 0) & 2**DAYS_OF_THE_WEEK.index(r)).zero?
    end.map {|day| day.to_sym}
  end
  
end