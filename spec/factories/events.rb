FactoryGirl.define do #not sure if it is right to have these integers as strings.  still works
  factory :event do
    sequence(:name) { |n| "Event #{n}" }
    category 'Scrum'
    description ''
    start_datetime '2014-03-07 23:30:00 UTC'
    duration '1'
    repeats 'weekly'
    repeats_every_n_weeks '1'
    repeats_weekly_each_days_of_the_week_mask '64'
    repeat_ends_string 'on'
    repeat_ends_on '2015-03-31'
    time_zone 'UTC'

    factory :single_event do
      repeats 'never'
    end

    factory :every_weekend_event do
      repeats_weekly_each_days_of_the_week_mask '96'
    end
  end
  factory :invalid_event do
    name nil
  end
end
