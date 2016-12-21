class ScrumsController < ApplicationController
  # before_action :session_timezone_offset
  #before index code is run, i want to make sure the session is set.  either don't run or redirect.
  def index
    @scrums = EventInstance.where(category: 'Scrum').last(20).sort {|a, b| b.created_at <=> a.created_at}
    base_scrums = Event.where(category: 'Scrum')
    upcoming_scrums = Event.list_upcoming_events_chronologically_with_repeats(base_scrums)
    # @upcoming_scrums = upcoming_scrums.group_by{|f| Date::DAYNAMES[f[:time].wday] }
    @upcoming_scrums = upcoming_scrums.group_by{|f| (f[:time] + session[:timezone_offset]).beginning_of_day }.map {|k,v| [Date::DAYNAMES[k.wday], v] }.to_h
    
    @keys = @upcoming_scrums.keys
    @timezone_offset = session[:timezone_offset]
    params[:count] ||= 0
    unless session[:timezone_offset] || params[:count].to_i > 3
      redirect_to scrums_path(:count => params[:count] = params[:count].to_i + 1)
    end
    
    # @upcoming_scrums = Event.upcoming_events_with_repeats(base_scrums)
  end
  
  
  private
  
  def timezone_offset
    if current_user 
      current_user.timezone_offset
    else
      0
    end
  end
  
  def session_timezone_offset
    unless session[:timezone_offset]
      
      session[:timezone_offset] = params[:timezone_offset]
    end
  end
  
  
# <% @keys.each do |key| %>
#   <%= key %>
#   <% @upcoming_scrums[key].each do |event| %>
#     <%= event.name %>
#   <% end %>
# <% end %>
  
  
end
