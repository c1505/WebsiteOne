class Recurrence
  # def initialize(events)
  #   @events = events
  # end
  
  include IceCube
  
  COLLECTION_TIME_FUTURE = 10.days
  COLLECTION_TIME_PAST = 15.minutes
  
  #this returns a hash with the base event and the time of the upcoming event
  def self.upcoming_events(events)
    events.inject([]) do |memo, event|
      memo << event.next_occurrences
    end.flatten.sort_by { |e| e[:time] }
  end
  
  def next_occurrences(options = {})
    begin_datetime = start_datetime_for_collection(options)
    final_datetime = final_datetime_for_collection(options)
    limit = options.fetch(:limit, 100)
    [].tap do |occurences|
      occurrences_between(begin_datetime, final_datetime).each do |time|
        occurences << { event: self, time: time }
        return occurences if occurences.count >= limit
      end
    end
  end
  
  def start_datetime_for_collection(options = {})
    first_datetime = options.fetch(:start_time, COLLECTION_TIME_PAST.ago)
    first_datetime = [start_datetime, first_datetime.to_datetime].max
    first_datetime.to_datetime.utc
  end
  
  def final_datetime_for_collection(options = {})
    if repeating_and_ends? && options[:end_time].present?
      final_datetime = [options[:end_time], repeat_ends_on.to_datetime].min
    elsif repeating_and_ends?
      final_datetime = repeat_ends_on.to_datetime
    else
      final_datetime = options[:end_time]
    end
    final_datetime ? final_datetime.to_datetime.utc : COLLECTION_TIME_FUTURE.from_now
  end
  
  
  
  
  # def schedule() #why does this have parens and no parameter that it is taking?  
  #   sched = series_end_time.nil? || !repeat_ends ? IceCube::Schedule.new(start_datetime) : IceCube::Schedule.new(start_datetime, :end_time => series_end_time)
  #   case repeats
  #     when 'never'
  #       sched.add_recurrence_time(start_datetime)
  #     when 'weekly'
  #       days = repeats_weekly_each_days_of_the_week.map { |d| d.to_sym }
  #       sched.add_recurrence_rule IceCube::Rule.weekly(repeats_every_n_weeks).day(*days)
  #   end
  #   self.exclusions ||= []
  #   self.exclusions.each do |ex|
  #     sched.add_exception_time(ex)
  #   end
  #   sched
  # end
  
end
