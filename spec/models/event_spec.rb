require 'spec_helper'

describe Event, :type => :model do
  before(:each) do
    ENV['TZ'] = 'UTC'
  end

  after(:each) do
    Delorean.back_to_the_present
  end

  subject(:event) { build_stubbed :event }

  it { is_expected.to respond_to :project_id }
  it { is_expected.to respond_to :friendly_id }
  it { is_expected.to respond_to :schedule }
  it { is_expected.to respond_to :live? }
  it { should belong_to :creator }

  it 'is valid with all the correct parameters' do
    expect(subject).to be_valid
  end

  it 'is invalid without name' do
    expect(FactoryGirl.build(:event, name: nil)).to_not be_valid
  end

  it 'is invalid without category' do
    expect(FactoryGirl.build(:event, category: nil)).to_not be_valid
  end

  it 'is invalid without repeats' do
    expect(FactoryGirl.build(:event, repeats: nil)).to_not be_valid
  end

  it 'is invalid with invalid url' do
    expect(FactoryGirl.build(:event, url: 'http:google.com')).to_not be_valid
  end

  describe "#less_than_ten_till_start?" do

    before(:each) { Delorean.time_travel_to '2014-03-16 23:30:00 UTC' }

    context 'event starts five minutes from now' do
      subject(:event) { build_stubbed :event, start_datetime: '2014-03-07 23:35:00 UTC' }
      it 'returns true' do
        expect(event).to be_less_than_ten_till_start
      end
    end

    context 'event starts 20 minutes from now' do
      subject(:event) { build_stubbed :event, start_datetime: '2014-03-07 23:50:00 UTC' }
      it 'returns false' do
        expect(event).not_to be_less_than_ten_till_start
      end
    end

    context 'event started five minutes ago and has not ended' do
      subject(:event) { build_stubbed :event, start_datetime: '2014-03-07 23:25:00 UTC' , duration: '10'}
      it 'returns true' do
        expect(event).to be_less_than_ten_till_start
      end
    end

    context 'event finished 10 minutes ago' do
      subject(:event) { build_stubbed :event, start_datetime: '2014-03-16 23:10:00 UTC', duration: '10' }
      it 'returns false' do
        expect(event).not_to be_less_than_ten_till_start
      end
    end

    context 'event sequence has been terminated' do
      subject(:event) { build_stubbed :event, start_datetime: '2014-03-07 23:50:00 UTC', repeat_ends_on: '2014-03-10' }
      it 'returns false' do
        expect(event).not_to be_less_than_ten_till_start
      end
    end
  end

  context 'should create a scrum event that ' do
    ### FIXME these test schedule rather than the public methods
    it 'is scheduled for one occasion' do
      event = FactoryGirl.build_stubbed(:single_event,
                                        start_datetime: 'Mon, 17 Jun 2013 09:00:00 UTC',
                                        duration: 600,
                                        repeat_ends_on: 'Mon, 17 Jun 2013',
                                        time_zone: 'Eastern Time (US & Canada)')
      expect(event.schedule.first(5)).to eq(['Mon, 17 Jun 2013 09:00:00 UTC +00:00'])
    end

    it 'is scheduled for every weekend' do
      event = FactoryGirl.build_stubbed(Event,
                                        name: 'every weekend event',
                                        category: 'Scrum',
                                        description: '',
                                        start_datetime: 'Mon, 17 Jun 2013 09:00:00 UTC',
                                        duration: 600,
                                        repeats: 'weekly',
                                        repeats_every_n_weeks: 1,
                                        repeats_weekly_each_days_of_the_week_mask: 96,
                                        repeat_ends: 'never',
                                        repeat_ends_on: 'Tue, 25 Jun 2013',
                                        time_zone: 'Eastern Time (US & Canada)')
      expect(event.schedule.first(5)).to eq(['Sat, 22 Jun 2013 09:00:00 UTC +00:00', 'Sun, 23 Jun 2013 09:00:00 UTC +00:00', 'Sat, 29 Jun 2013 09:00:00 UTC +00:00', 'Sun, 30 Jun 2013 09:00:00 UTC +00:00', 'Sat, 06 Jul 2013 09:00:00 UTC +00:00'])
    end

    it 'is scheduled for every Sunday' do
      event = FactoryGirl.build_stubbed(Event,
                                        name: 'every Sunday event',
                                        category: 'Scrum',
                                        description: '',
                                        start_datetime: 'Mon, 17 Jun 2013 09:00:00 UTC',
                                        duration: 600,
                                        repeats: 'weekly',
                                        repeats_every_n_weeks: 1,
                                        repeats_weekly_each_days_of_the_week_mask: 64,
                                        repeat_ends: 'never',
                                        repeat_ends_on: 'Mon, 17 Jun 2013',
                                        time_zone: 'Eastern Time (US & Canada)')
      expect(event.schedule.first(5)).to eq(['Sun, 23 Jun 2013 09:00:00 UTC +00:00', 'Sun, 30 Jun 2013 09:00:00 UTC +00:00', 'Sun, 07 Jul 2013 09:00:00 UTC +00:00', 'Sun, 14 Jul 2013 09:00:00 UTC +00:00', 'Sun, 21 Jul 2013 09:00:00 UTC +00:00'])
    end

    it 'is scheduled for every Monday' do
      event = FactoryGirl.build_stubbed(Event,
                                        name: 'every Monday event',
                                        category: 'Scrum',
                                        description: '',
                                        start_datetime: 'Mon, 17 Jun 2013 09:00:00 UTC',
                                        duration: 600,
                                        repeats: 'weekly',
                                        repeats_every_n_weeks: 1,
                                        repeats_weekly_each_days_of_the_week_mask: 1,
                                        repeat_ends: 'never',
                                        repeat_ends_on: 'Mon, 17 Jun 2013',
                                        time_zone: 'UTC')
      expect(event.schedule.first(5)).to eq(['Mon, 17 Jun 2013 09:00:00 GMT +00:00', 'Mon, 24 Jun 2013 09:00:00 GMT +00:00', 'Mon, 01 Jul 2013 09:00:00 GMT +00:00', 'Mon, 08 Jul 2013 09:00:00 GMT +00:00', 'Mon, 15 Jul 2013 09:00:00 GMT +00:00'])
    end
  end

  context 'should create a hookup event that' do
    before do
      @event = FactoryGirl.build_stubbed(Event,
                                         name: 'PP Monday event',
                                         category: 'PairProgramming',
                                         start_datetime: 'Mon, 17 Jun 2014 09:00:00 UTC',
                                         duration: 90,
                                         repeats: 'never',
                                         time_zone: 'UTC')
    end

    it 'should expire events that ended' do
      hangout = @event.event_instances.create(hangout_url: 'anything@anything.com',
                                              updated_at: '2014-06-17 10:25:00 UTC')
      allow(hangout).to receive(:started?).and_return(true)
      Delorean.time_travel_to(Time.parse('2014-06-17 10:31:00 UTC'))
      expect(@event).to_not be_live
    end

    it 'should mark as active events which have started and have not ended' do
      @event.event_instances.create(hangout_url: 'anything@anything.com',
                                              updated_at: '2014-06-17 10:25:00 UTC')
      Delorean.time_travel_to(Time.parse('2014-06-17 10:26:00 UTC'))
      expect(@event).to be_live
    end

    it 'should not be started if events have not started' do
      @event.event_instances.create(hangout_url: nil,
                                              updated_at: nil)
      Delorean.time_travel_to(Time.parse('2014-06-17 9:30:00 UTC'))
      expect(@event.live?).to be_falsey
    end
  end

  context 'Event url' do

    it 'should be set if valid' do
      event = FactoryGirl.build(Event, :url => 'http://google.com')
      expect(event.save).to be_truthy
    end

    it 'should be rejected if invalid' do
      event = FactoryGirl.build(Event, :url => 'http:google.com')
      event.valid?
      expect(event.errors[:url].size).to eq(1)
    end
  end

  describe '#next_event_occurrence_with_time' do
    before(:each) do
      @event = FactoryGirl.build(Event,
                                 name: 'Spec Scrum',
                                 start_datetime: 'Mon, 10 Jun 2013 09:00:00 UTC',
                                 duration: 30,
                                 repeats: 'weekly',
                                 repeats_every_n_weeks: 1,
                                 repeats_weekly_each_days_of_the_week_mask: 0b1000000,
                                 repeat_ends: true,
                                 repeat_ends_on: '2013-07-01')
    end

    it 'should return the first event instance with its time in basic case' do
      Delorean.time_travel_to(Time.parse('2013-06-15 09:27:00 UTC'))
      expect(@event.next_event_occurrence_with_time[:time]).to eq('2013-06-16 09:00:00 UTC')
    end

    it 'should return nil if the series has expired' do
      Delorean.time_travel_to(Time.parse('2013-07-15 09:27:00 UTC'))
      expect(@event.next_event_occurrence_with_time).to be_nil
    end

    it 'should return the second event instance when the start time is moved forward' do
      Delorean.time_travel_to(Time.parse('2013-06-20 09:27:00 UTC'))
      expect(@event.next_event_occurrence_with_time[:time]).to eq('2013-06-23 09:00:00 UTC')
    end

    it 'should return the second event instance with its time when the first is deleted' do
      Delorean.time_travel_to(Time.parse('2013-06-15 09:27:00 UTC'))
      @event.remove_from_schedule(Time.parse('2013-6-16 09:00:00 UTC'))
      expect(@event.next_event_occurrence_with_time[:time]).to eq('2013-06-23 09:00:00 UTC')
    end

    it 'should return the event instance when it is not recurring and the event occurs in the future' do
      @event.update_attribute(:repeats, 'never')
      Delorean.time_travel_to(Time.parse('2013-06-05 09:27:00 UTC'))
      expect(@event.next_event_occurrence_with_time[:time]).to eq('2013-06-10 09:00:00 UTC')
    end

    it 'should not return the event instance when it is not recurring' do
      @event.update_attribute(:repeats, 'never')
      Delorean.time_travel_to(Time.parse('2013-06-15 09:27:00 UTC'))
      expect(@event.next_event_occurrence_with_time).to be_nil
    end
  end

  describe '#next_occurences' do
    before do
      @event = FactoryGirl.build_stubbed(Event,
                                         name: 'Spec Scrum',
                                         start_datetime: '2014-03-07 10:30:00 UTC',
                                         duration: 30)
      allow(@event).to receive(:repeats).and_return('weekly')
      allow(@event).to receive(:repeats_every_n_weeks).and_return(1)
      allow(@event).to receive(:repeats_weekly_each_days_of_the_week_mask).and_return(0b1111111)
      allow(@event).to receive(:repeat_ends).and_return(true)
      allow(@event).to receive(:repeat_ends_on).and_return('Tue, 25 Jun 2015')
      allow(@event).to receive(:friendly_id).and_return('spec-scrum')
    end

    context 'test against start_datetime and repeat_ends_on' do

      it 'already ended in the past' do
        Delorean.time_travel_to(Time.parse('2016-02-07 09:27:00 UTC'))
        expect(@event.next_occurrences.count).to eq(0)
      end
    end

    context 'with input arguments' do
      context ':limit option' do

        it 'should limit the size of the output' do
          options = {limit: 2}
          Delorean.time_travel_to(Time.parse('2014-03-08 09:27:00 UTC'))
          expect(@event.next_occurrences(options).count).to eq(2)
        end
      end

    end
  end

  describe 'Event#start_datetime_for_collection for starting event' do
    before do
      @event = FactoryGirl.build_stubbed(Event,
                                         name: 'Spec Scrum never ends',
                                         start_datetime: '2014-03-07 10:30:00 UTC',
                                         duration: 30)
    end

  end

  describe 'Event.next_event_occurence' do
    @event = FactoryGirl.build(Event,
                               category: 'Scrum',
                               name: 'Spec Scrum one-time',
                               start_datetime: '2014-03-07 10:30:00 UTC',
                               duration: 30,
                               repeats: 'never'
    )

    it 'should return the next event occurence' do
      Delorean.time_travel_to(Time.parse('2014-03-07 09:27:00 UTC'))
      expect(Event.next_occurrence(:scrum)).to eq @event
    end

    it 'should return events that were schedule 15 minutes earlier or less' do
      Delorean.time_travel_to(Time.parse('2014-03-07 10:44:59 UTC'))
      expect(Event.next_occurrence(:scrum)).to eq @event
    end

    it 'should not return events that were scheduled to start more than 15 minutes ago' do
      Delorean.time_travel_to(Time.parse('2014-03-07 10:45:01 UTC'))
      expect(Event.next_occurrence(:scrum)).to be_nil
    end

    it 'should return events that were schedule 30 minutes earlier or less if we change collection_time_past to 30.minutes' do
      Delorean.time_travel_to(Time.parse('2014-03-07 10:59:59 UTC'))
      expect(Event.next_occurrence(:scrum, 30.minutes.ago)).to eq @event
    end
  end

  describe '#recent_hangouts' do
    before(:each) do
      event.event_instances.create(created_at: Date.yesterday, updated_at: Date.yesterday + 15.minutes)
      @recent_hangout = event.event_instances.create(created_at: 1.second.ago, updated_at: 1.second.ago)
    end

    it 'returns only the hangouts updated between yesterday and today' do
      expect(event.recent_hangouts.to_a).to match_array([@recent_hangout])
    end
  end

  describe '#upcoming_events' do
    before(:each) do
      FactoryGirl.create(Event,
                                 category: 'Scrum',
                                 name: 'Spec Scrum one-time',
                                 start_datetime: '2015-06-15 09:20:00 UTC',
                                 duration: 30,
                                 repeats: 'never'
      )
      FactoryGirl.create(Event,
                                 category: 'Scrum',
                                 name: 'Spec Scrum one-time',
                                 start_datetime: '2015-06-15 09:25:00 UTC',
                                 duration: 30,
                                 repeats: 'never'
      )
    end

    it 'shows future events' do
      Delorean.time_travel_to(Time.parse('2015-06-15 09:25:00 UTC'))
      expect(Event.upcoming_events.count).to eq(2)
    end

    it 'does not show finished events' do
      Delorean.time_travel_to(Time.parse('2015-06-15 09:51:00 UTC'))
      expect(Event.upcoming_events.count).to eq(1)
    end

    it 'returns event 1 minute before ending' do
      Delorean.time_travel_to(Time.parse('2015-06-15 09:54:00 UTC'))
      expect(Event.upcoming_events.count).to eq(1)
    end

    it 'does not return event 1 minute after ending' do
      Delorean.time_travel_to(Time.parse('2015-06-15 09:56:00 UTC'))
      expect(Event.upcoming_events.count).to eq(0)
    end

    it 'returns event past event duration, but still live' do
      event_instance = FactoryGirl.create(EventInstance)
      event_end_time = event_instance.event.start_datetime + event_instance.event.duration.minutes
      expect(event_end_time).to be < Time.current
      expect(event_instance.event).to eq(Event.upcoming_events.last[:event])
    end

  end

  describe '#upcoming_events' do
  before(:each) do
    FactoryGirl.create(Event,
                               category: 'Scrum',
                               name: 'Spec Scrum one-time',
                               start_datetime: '2015-06-15 09:20:00 UTC',
                               duration: 30,
                               repeats: 'never'
    )
    FactoryGirl.create(Event,
                               category: 'Scrum',
                               name: 'Spec Scrum one-time',
                               start_datetime: '2015-06-15 09:25:00 UTC',
                               duration: 30,
                               repeats: 'never'
    )
  end

  it 'shows future events' do
    Delorean.time_travel_to(Time.parse('2015-06-15 09:25:00 UTC'))
    expect(Event.upcoming_events.count).to eq(2)
  end

  it 'does not show finished events' do
    Delorean.time_travel_to(Time.parse('2015-06-15 09:51:00 UTC'))
    expect(Event.upcoming_events.count).to eq(1)
  end

  it 'returns event 1 minute before ending' do
    Delorean.time_travel_to(Time.parse('2015-06-15 09:54:00 UTC'))
    expect(Event.upcoming_events.count).to eq(1)
  end

  it 'does not return event 1 minute after ending' do
    Delorean.time_travel_to(Time.parse('2015-06-15 09:56:00 UTC'))
    expect(Event.upcoming_events.count).to eq(0)
  end

  it 'returns event past event duration, but still live' do
    event_instance = FactoryGirl.create(EventInstance)
    event_end_time = event_instance.event.start_datetime + event_instance.event.duration.minutes
    expect(event_end_time).to be < Time.current
    expect(event_instance.event).to eq(Event.upcoming_events.last[:event])
  end

  it 'returns repeating events'

  it 'returns non-repeating events'

    describe 'returns repeating events' do
  before(:each) do
    FactoryGirl.create(:single_event,
                                      start_datetime: 'Mon, 17 Jun 2013 09:00:00 UTC',
                                      time_zone: 'Eastern Time (US & Canada)')

    FactoryGirl.create(:every_weekend_event,
                                      start_datetime: 'Mon, 17 Jun 2013 09:00:00 UTC',
                                      repeat_ends: false,
                                      repeat_ends_on: 'Tue, 25 Jun 2018',
                                      time_zone: 'Eastern Time (US & Canada)')

    FactoryGirl.create(Event,
                                      name: 'every Sunday event',
                                      category: 'Scrum',
                                      description: '',
                                      start_datetime: 'Mon, 17 Jun 2013 09:00:00 UTC',
                                      duration: 600,
                                      repeats: 'weekly',
                                      repeats_every_n_weeks: 1,
                                      repeats_weekly_each_days_of_the_week_mask: 64,
                                      repeat_ends: false,
                                      repeat_ends_on: 'Mon, 17 Jun 2018',
                                      time_zone: 'Eastern Time (US & Canada)')

    FactoryGirl.create(Event,
                                      name: 'every Monday event',
                                      category: 'Scrum',
                                      description: '',
                                      start_datetime: 'Mon, 17 Jun 2013 09:00:00 UTC',
                                      duration: 60,
                                      repeats: 'weekly',
                                      repeats_every_n_weeks: 1,
                                      repeats_weekly_each_days_of_the_week_mask: 1,
                                      repeat_ends: true,
                                      repeat_ends_on: 'Mon, 16 Jun 2013',
                                      time_zone: 'UTC')
  end

  it 'shows repeating events' do #Change Refactor Test
    # expect(Event.upcoming_events).to eq(Event.refactored_upcoming_events)
  end

   it 'does not show events past repeat end' do
     Delorean.time_travel_to(Time.parse('2013-06-17 08:00:01 UTC'))
    # expect(Event.upcoming_events).to eq Event.refactored_upcoming_events
   end
 end

describe 'returns one time events' do
  before(:each) do
    @event3 = FactoryGirl.create(:single_event,
            start_datetime: 'Mon, 17 Jun 2013 09:00:00 UTC',
            time_zone: 'Eastern Time (US & Canada)')

    @event4 = FactoryGirl.create(:single_event,
            name: 'expired one time event',
            start_datetime: 'Mon, 17 Jun 2013 06:00:00 UTC',
            duration: 60,
            time_zone: 'Eastern Time (US & Canada)')
  end

  it 'shows one time events until event is finished' do
    Delorean.time_travel_to(Time.parse('2013-06-17 08:00:01 UTC'))
    expect(Event.upcoming_events.count).to eq 1
    expect(Event.upcoming_events.first[:event]).to eq(@event3)
  end

# what would fail?
  # events in different order
    #returns events sorted by time
  # event not in the right format
  # events included that shouldn't be
  # events not included that should be
  # whole hash in the wrong format
  # incorrect time scheduled
  # incorrect day scheduled
end

  end
end
