class Recurrence
  attr_reader :event, :start_time, :end_time, :collection_end, :collection_start #probably should just be a reader
  def initialize(event)
    @event = event
    @collection_start = Time.current - COLLECTION_TIME_PAST #this shoul also include the time not just the day i think.  
    @collection_end = Time.current + COLLECTION_TIME_FUTURE
  end
  
  include IceCube
  
  COLLECTION_TIME_FUTURE = 10.days
  COLLECTION_TIME_PAST = 15.minutes
  
  DAYS_OF_THE_WEEK = %w[monday tuesday wednesday thursday friday saturday sunday]
  
  ##### New Code ######
  def next_occurrences(options = {})
    schedule = IceCube::Schedule.new(collection_start_including_event_time)
    
    schedule.add_recurrence_rule( IceCube::Rule.weekly.day(recurring_days) )
    occurrences = schedule.occurrences(end_time)
    arr = [] #implement with tap
    occurrences.each do |occurrence|
      arr << { event: event, time: occurrence }
    end
    arr
    # binding.pry #not sure if the previous method took into account reccurence ending
    # only recurring events should make it here
    # repeats is currently 'weekly' and 'never'.  it should be true and false.  
  end
  
  private
  
  def collection_start_including_event_time
    collection_start.change( { hour: event.start_time.hour, min: event.start_time.min})
  end
  
  def end_time
    if event.repeat_ends_on < collection_end
      # event.repeat_ends_on #fix_me
      collection_end #this is wrong
    else
      collection_end
    end
  end
  
  def recurring_days
    DAYS_OF_THE_WEEK.reject do |r|
      ((event.repeats_weekly_each_days_of_the_week_mask || 0) & 2**DAYS_OF_THE_WEEK.index(r)).zero?
    end.map {|day| day.to_sym}
  end
  
    
  
  # start_time = Time.current - COLLECTION_TIME_PAST
  # end_time = Time.current + COLLECTION_TIME_FUTURE
  

  
  
  
  ##### New Code #####
  
  # def next_occurrences(options = {})
  #   # begin_datetime = start_datetime_for_collection(options)
  #   # final_datetime = final_datetime_for_collection(options)
  #   limit = options.fetch(:limit, 100)
  #   [].tap do |occurences|
  #     occurrences_between(start_datetime_for_collection, final_datetime_for_collection).each do |time|
  #       occurences << { event: event, time: time }
  #       return occurences if occurences.count >= limit
  #     end
  #   end
  # end
  
  def start_datetime_for_collection(options = {}) #is this :start_time just for testing purposes?
    first_datetime = options.fetch(:start_time, COLLECTION_TIME_PAST.ago)
    first_datetime = [event.start_datetime, first_datetime.to_datetime].max
    first_datetime.to_datetime.utc
  end
  
  def final_datetime_for_collection(options = {})
    if repeating_and_ends? && options[:end_time].present?
      final_datetime = [options[:end_time], event.repeat_ends_on.to_datetime].min
    elsif repeating_and_ends?
      final_datetime = event.repeat_ends_on.to_datetime
    else
      final_datetime = options[:end_time]
    end
    final_datetime ? final_datetime.to_datetime.utc : COLLECTION_TIME_FUTURE.from_now
  end

  def occurrences_between(start_time, end_time) #calls the icecube method inside
    schedule.occurrences_between(start_time.to_time, end_time.to_time)
  end

  def repeating_and_ends? #maybe move back event.  also figure out if 'never' is doing what
  # it should be doing.  tests use never, but database is now setup as boolean
    event.repeats != 'never' && event.repeat_ends && !event.repeat_ends_on.blank?
  end

  def schedule #why does this have parens and no parameter that it is taking?
    sched = series_end_time.nil? || !event.repeat_ends ? IceCube::Schedule.new(event.start_datetime) : IceCube::Schedule.new(event.start_datetime, :end_time => series_end_time)
    case event.repeats
    when 'never' # this has been changed to boolean in the database
      sched.add_recurrence_time(event.start_datetime)
    when 'weekly'
      days = repeats_weekly_each_days_of_the_week.map { |d| d.to_sym }
      sched.add_recurrence_rule IceCube::Rule.weekly(event.repeats_every_n_weeks).day(*days)
    end
    event.exclusions ||= []
    event.exclusions.each do |ex|
      sched.add_exception_time(ex)
    end
    sched
  end

  def series_end_time
    event.repeat_ends && event.repeat_ends_on.present? ? event.repeat_ends_on.to_time : nil
  end

  # def recurring_days
  #   DAYS_OF_THE_WEEK.reject do |r|
  #     ((event.repeats_weekly_each_days_of_the_week_mask || 0) & 2**DAYS_OF_THE_WEEK.index(r)).zero?
  #   end
  # end
  
  #below here unrelated to fetching list of recurring events

  def next_occurrence_time_method(start = Time.now)
    next_occurrence = next_event_occurrence_with_time(start)
    next_occurrence.present? ? next_occurrence[:time] : nil
  end

  def self.next_occurrence(event_type, begin_time = COLLECTION_TIME_PAST.ago) #move this too
    events_with_times = []
    events_with_times = Event.where(category: event_type).map { |event|
      event.next_event_occurrence_with_time(begin_time)
    }.compact
    return nil if events_with_times.empty?
    events_with_times = events_with_times.sort_by { |e| e[:time] }
    events_with_times[0][:event].next_occurrence_time_attr = events_with_times[0][:time]
    return events_with_times[0][:event]
  end
  
  def next_event_occurrence_with_time(start = Time.now, final= 2.months.from_now) #why both this and the previous method?  
    begin_datetime = start_datetime_for_collection(start_time: start) #unused local varialbe
    final_datetime = repeating_and_ends? ? repeat_ends_on : final
    n_days = 8
    end_datetime = n_days.days.from_now
    event = nil
    return next_event_occurrence_with_time_inner(start, final_datetime) if self.repeats == 'never'
    while event.nil? && end_datetime < final_datetime
      event = next_event_occurrence_with_time_inner(start, final_datetime)
      n_days *= 2
      end_datetime = n_days.days.from_now
    end
    event
  end

  def next_event_occurrence_with_time_inner(start_time, end_time)
    occurrences = occurrences_between(start_time, end_time)
    { event: self, time: occurrences.first.start_time } if occurrences.present?
  end
  
  def remove_from_schedule(timedate) #looks like this is only used in a test and not in running code.  do we want it?  
    if timedate >= Time.now && timedate == next_occurrence_time_method
      _next_occurrences = next_occurrences(limit: 2)
      self.start_datetime = (_next_occurrences.size > 1) ? _next_occurrences[1][:time] : timedate + 1.day
    elsif timedate >= Time.now
      self.exclusions ||= []
      self.exclusions << timedate
    end
    save!
  end
  
  def less_than_ten_till_start?
    return true if within_current_event_duration?
    Time.now > next_event_occurrence_with_time[:time] - 10.minutes
  rescue
    false
  end
  
  def within_current_event_duration? #doesn't seem to be used
    after_current_start_time? and before_current_end_time?
  end
  
  def before_current_end_time? #doesn't seem to be used
    Time.now < (schedule.previous_occurrence(Time.now) + duration*60)
  rescue
    false
  end

  def after_current_start_time? #doesn't seem to be used
    Time.now > schedule.previous_occurrence(Time.now)
  rescue
    false
  end
  
end
