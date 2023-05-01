# # frozen_string_literal: true

require "sinatra/base"
require "sinatra/reloader"
require "sinatra/activerecord"
require "bcrypt"
require "simple_calendar"
require "date"
require "pony"
require_relative "lib/booking"
require_relative "lib/property"
require_relative "lib/user"
require_relative "lib/availability"
require_relative "lib/email"

class MakersBnB < Sinatra::Base
  enable :sessions
  configure :development do
    register Sinatra::Reloader
  end

  use Rack::Session::Cookie, :key => "rack.session",
                             :path => "/",
                             :secret => ENV.fetch("SESSION_SECRET") { SecureRandom.hex(20) }

  get "/" do
    @a = logged_in
    @properties = Property.all
    return erb(:homepage)
  end

  get "/log-in" do
    return erb(:log_in)
  end

  get "/sign_up" do
    return erb(:sign_up)
  end

  post "/approve-reject/:id&:bool" do
    booking = Booking.find(params[:id].to_i)
    booking.responded = true
    property = Property.find(booking.property_id)
    user = User.find(booking.user_id)
    notification = EmailTag.new
    params[:start_date], params[:end_date] = booking.start_date, booking.end_date
    params[:property_id] = property.id
    if params[:bool] == "true"
      booking.approved = true
      renter = User.find(property.user_id)
      notification.send(user.email, "Request accepted", "Your request for #{property.title} from the #{booking.start_date} to the #{booking.end_date} has been accepted by the host.")
      notification.send(renter.email, "Confirmed a request", "You have confirmed a request for #{property.title} from the #{booking.start_date} to the #{booking.end_date}.")
      availabilities = Avail.where("property_id = ?", params[:property_id])
      availabilities.each do |availability|
        if compatible(availability)
          availability_updater(availability)
          break
        end
      end
    else
      notification.send(user.email, "Request denied", "Your request for #{property.title} from the #{booking.start_date} to the #{booking.end_date} has been rejected by the host.")
      booking.approved = false
    end
    booking.save
    redirect("/account")
  end

  get "/bookings" do
    if session[:user_id].nil?
      return ""
    else
      @trips = Booking.joins(:property).select("bookings.*, properties.*").where("user_id" => session[:user_id])
      erb(:bookings)
    end
  end

  get "/log-out" do
    session.clear
    redirect "/"
  end

  get "/add-a-space" do
    logged_in ? erb(:add_a_space) : erb(:log_in_error)
  end

  post "/add-a-space" do
    if logged_in
      property = Property.create(user_id: session[:user_id], title: params[:title], address: params[:address], description: params[:description], daily_rate: params[:daily_rate])
      Avail.create(property_id: property.id, first_available: params[:first_available], last_available: params[:last_available])
      user = User.find(session[:user_id])
      notification = EmailTag.new
      notification.send(user.email, "Added a space", "You have listed #{params[:title]} for £#{params[:daily_rate]} per night, from the #{params[:first_available]} to the #{params[:last_available]}.")
      p = Property.all.last
      redirect "/add-availability/#{p.id}"
    else
      redirect "/"
    end
  end

  get "/account" do
    @requests = Booking.joins(:property).select(
      "bookings.id",
      "properties.title",
      "properties.description",
      "properties.daily_rate"
    ).where(["properties.user_id = ? and bookings.responded = ?", session[:user_id], false])

    return erb(:account_page)
  end

  post "/bookings" do
    return login_fail unless logged_in
    availabilities = Avail.where("property_id = ?", params[:property_id])
    availabilities.each do |availability|
      if compatible(availability)
        Booking.create(user_id: session[:user_id], property_id: params[:property_id],
                       start_date: params[:start_date], end_date: params[:end_date],
                       approved: false, responded: false)
        property = Property.find(params[:property_id])
        user = User.find(session[:user_id])
        notification = EmailTag.new
        notification.send(user.email, "Created a booking request", "You have made a booking request for #{property.title} from the #{params[:start_date]} to the #{params[:end_date]}. Please await approval from the host.")
        renter = User.find(property.user_id)

        notification.send(renter.email, "Booking request recieved", "You have recieved a booking request for #{property.title} from the #{params[:start_date]} to the #{params[:end_date]}. Please accept or reject the request.")

        return erb(:booking_confirmation)
      end
    end
    redirect("/property/#{params[:property_id]}?try_again=true")
  end

  get "/add-availability/:id" do
    @p = Property.find(params[:id])
    return erb(:add_availability)
  end

  post "/add-availability/:id" do
    return login_fail unless logged_in
    Avail.create(property_id: params[:id], first_available: params[:first_available], last_available: params[:last_available])
    redirect back
  end

  post "/log-in" do
    email = params[:email]
    password = params[:password]

    user = User.find_by(email: email)
    return erb(:log_in_error) if user.nil?
    if user.authenticate(password)
      session[:user_id] = user.id
      redirect "/"
    else
      status 400
      return erb(:log_in_error)
    end
  end

  get "/sign-up" do
    return erb(:sign_up)
  end

  post "/sign-up" do
    encrypted_password = BCrypt::Password.create(params[:password])
    @user = User.create(first_name: params[:first_name], last_name: params[:last_name], email: params[:email], password_digest: encrypted_password)
    if @user.errors.empty?
      notification = EmailTag.new
      notification.send(params[:email], "Sign up to MakersBnb", "Congratulations on signing up to MakersBnb.")
      return erb(:sign_up_confirmation)
    else
      status 400
      return erb(:sign_up_error)
    end
  end

  get "/property/:id" do
    redirect "/log-in" unless logged_in
    @try_again = params[:try_again]
    @property = Property.find(params[:id])
    @dates = Avail.where("property_id = ?", params[:id])

    return erb(:book_a_space)
  end

  private

  def logged_in
    if session[:user_id] == nil
      return false
    else
      return true
    end
  end

  def login_fail
    status 400
    erb(:log_in_error)
  end

  def availability_updater(date)
    if params[:start_date].to_date > date.first_available && params[:end_date].to_date < date.last_available
      Avail.create(property_id: params[:property_id], first_available: date.first_available, last_available: params[:start_date].to_date.prev_day)
      Avail.create(property_id: params[:property_id], first_available: params[:end_date].to_date.next_day, last_available: date.last_available)
    elsif params[:start_date].to_date == date.first_available && params[:end_date].to_date == date.last_available
    elsif params[:start_date].to_date == date.first_available
      Avail.create(property_id: params[:property_id], first_available: date.first_available, last_available: params[:end_date].to_date.next_day)
    elsif params[:end_date].to_date == date.last_available
      Avail.create(property_id: params[:property_id], first_available: date.first_available, last_available: params[:start_date].to_date.prev_day)
    end
    Avail.find(date.id).destroy
  end

  def compatible(availability)
    params[:start_date].to_date >= availability.first_available && params[:end_date].to_date <= availability.last_available
  end
end
