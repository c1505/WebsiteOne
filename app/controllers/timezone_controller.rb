class TimezoneController < ActionController::Base
  # skip_before_action :verify_authenticity_token
  def create
    #FIX_ME
    timezone_offset_hours = params[:timezone_offset].to_i / 60
    utc_timezone_offset = -timezone_offset_hours
    # session[:timezone_offset] ||= timezone_offset
    if current_user && current_user.timezone_offset
      session[:timzone_offset] = current_user.timezone_offset
    else
      session[:timezone_offset] = timezone_offset
    end
    render json: session[:timezone_offset]
  end
  
  private
  
  
end