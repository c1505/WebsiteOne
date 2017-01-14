class Recurrence
  attr_accessor :event
  def initialize(event)
    @event = event
  end
  
  include IceCube
  
  COLLECTION_TIME_FUTURE = 10.days
  COLLECTION_TIME_PAST = 15.minutes
  
  DAYS_OF_THE_WEEK = %w[monday tuesday wednesday thursday friday saturday sunday]
  
  def next_occurrences(options = {})
    begin_datetime = start_datetime_for_collection(options)
    final_datetime = final_datetime_for_collection(options)
    limit = options.fetch(:limit, 100)
    [].tap do |occurences|
      occurrences_between(begin_datetime, final_datetime).each do |time|
        occurences << { event: event, time: time }
        return occurences if occurences.count >= limit
      end
    end
  end
  
  def start_datetime_for_collection(options = {})
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

  def repeats_weekly_each_days_of_the_week
    DAYS_OF_THE_WEEK.reject do |r|
      ((event.repeats_weekly_each_days_of_the_week_mask || 0) & 2**DAYS_OF_THE_WEEK.index(r)).zero?
    end
  end
  
  #below here unrelated to fetching list of recurring events


  
end
