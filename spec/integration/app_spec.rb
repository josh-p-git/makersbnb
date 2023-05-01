require "spec_helper"
require "rack/test"
require_relative "../../app"
require "bcrypt"
require "pony"
require "email"

describe "MakersBnB" do
  include Rack::Test::Methods
  let(:app) { MakersBnB.new }

  def check200
    expect(@response.status).to eq 200
  end

  def check400
    expect(@response.status).to eq 400
  end

  def sign_up
    post("/sign-up?first_name=orhan&last_name=khanbayov&email=orhan.khanbayov@hotmail.co.uk&password=mypassword")
    # a = EmailTag.new
    # a.send("orhan.khanbayov@hotmail.co.uk", "testing", "testing")
  end

  def login
    post("/log-in?email=orhan.khanbayov@hotmail.co.uk&password=mypassword")
  end

  def second_sign_up
    post("/sign-up?first_name=Finn&last_name=McCoy&email=finnmccoy99@gmail.com&password=mypassword")
  end

  def second_log_in
    post("/log-in?email=finnmccoy99@gmail.com&password=mypassword")
  end

  context "GET /" do
    it "returns homepage with status 200" do
      @response = get("/")
      check200
      expect(@response.body).to include "MakersBnB"
    end

    it "returns list all properties" do
      @response = get("/")
      expect(@response.body).to include "K12"
      expect(@response.body).to include "93"
    end

    it "has log in button if logged out" do
      @response = get("/")
      expect(@response.body).to include "Click to login"
    end

    it "logs out if logout is pressed" do
      sign_up
      login
      get("/log-out")
      @response = get("/")
      check200
      expect(@response.body).to include "Click to login"
    end

    it "has logout button if logged in" do
      sign_up
      login
      @response = get("/")
      expect(@response.body).to include "Click to logout"
    end

    it "has a signup button if logged out" do
      @response = get("/")
      expect(@response.body).to include ("Click to sign up")
    end

    it "has a link to view bookings if logged in" do
      sign_up
      login
      @response = get("/")
      expect(@response.body).to include ("Click to view bookings")
    end
  end

  context "GET /log-in" do
    it "returns the html form to log in" do
      @response = get("/log-in")
      check200
      expect(@response.body).to include("<h1>Log In to MakersBnB</h1>")
      expect(@response.body).to include('<input type="text" name="email">')
      expect(@response.body).to include('<input type="password" name="password">')
    end
  end

  context "POST /log-in" do
    it "if valid credentials, returns your bookings page" do
      sign_up
      login
      @response = get("/bookings")
      check200
      expect(@response.body).to include("<h1>Your Bookings</h1>")
    end

    it "if invalid credentials, returns login_error page" do
      @response = post("/log-in",
                       email: "claretha@walter-dach.name",
                       password: "NKhqEmiBWNJXp")
      check400
      expect(@response.body).to include("<h1>Log In Error</h1>")
    end
  end

  context "GET /bookings when logged in" do
    it "returns the page of user bookings" do
      sign_up
      login
      post("/bookings",
           property_id: 10,
           start_date: "2023-04-21",
           end_date: "2023-04-22",
           approved: false)
      @response = get("/bookings")
      check200
      expect(@response.body).to include(
        "<h1>Your Bookings</h1>",
        "Your trip to Gasherbrum III",
        "A bit about your destination:",
        "Chuck Norris breaks RSA 128-bit encrypted codes in milliseconds."
      )
    end
  end
  #starts on 2023-04-21 and ends on 2023-04-22
  context "GET /sign-up" do
    it "returns sign-up page with 200 status" do
      @response = get("/sign-up")
      check200
      expect(@response.body).to include "email"
      expect(@response.body).to include "password"
    end
  end

  context "POST /sign-up" do
    it "creates user entry in database" do
      @response = sign_up
      check200
      expect(@response.body).to include "You're signed up to MakersBnB"
    end

    it "returns an error if email is already in use" do
      sign_up
      @response = sign_up
      check400
      expect(@response.body).to include "Email address already in use."
    end
  end

  context "GET /account" do
    it "returns a page containing your bookings that need to be approved" do
      sign_up
      login
      post("/add-a-space?title=Snowden&address=Excelsior Rd, Western Ave, Cardiff CF14 3AT&description=Time waits for no man.
        Unless that man is Chuck Norris.&daily_rate=100&first_available=2023-01-18&last_available=2023-04-30")
      get("/log-out")
      second_sign_up
      second_log_in
      post("/bookings",
           property_id: 21,
           start_date: "2023-04-18",
           end_date: "2023-04-20",
           approved: false)
      get("/log-out")
      login
      @response = get("/account")
      check200
      expect(@response.body).to include("Snowden")
    end
  end

  context "GET /add-a-space" do
    it "returns nothing if not logged in" do
      @response = get("/add-a-space")
      check200
      expect(@response.body).to include ""
    end
    it "returns add a space forms if logged in" do
      sign_up
      login
      @response = get("/add-a-space")
      check200
      expect(@response.body).to include ('<input type="text" name="title" />')
      expect(@response.body).to include ('<input type="text" name="address" />')
      expect(@response.body).to include ('<input type="text" name="description" />')
      expect(@response.body).to include ('<input type="number" name="daily_rate" />')
      expect(@response.body).to include ('<input type="date" name="first_available" />')
      expect(@response.body).to include ('<input type="date" name="last_available" />')
      expect(@response.body).to include ('<input type="submit" value="Submit the form" />')
    end
  end

  context "POST /add-a-space" do
    it "creates a property that can be viewed on the hompepage" do
      sign_up
      login
      post("/add-a-space?title=Snowden&address=Excelsior Rd, Western Ave, Cardiff CF14 3AT&description=Time waits for no man.
         Unless that man is Chuck Norris.&daily_rate=100&first_available=2023-01-18&last_available=2023-04-30")
      @response = get("/")
      check200
      expect(@response.body).to include "Snowden"
    end
  end

  context "GET /property/:id" do
    it "gets booking page for property with :id" do
      @response = get("/property/1")
      check200
      expect(@response.body).to include(
        "<h1>Book a space</h1>",
        "K12",
        "Chuck Norris doesn't delete files, he blows them away."
      )
    end
  end

  context "POST /bookings" do
    it "adds users booking to the bookings table, two new availabilities should be created, one destroyed" do
      sign_up
      login
      @response = post("/bookings",
                       property_id: 10,
                       start_date: "2023-04-18",
                       end_date: "2023-04-20",
                       approved: false)
      #check200
      expect(Booking.last.property_id).to eq(10)
      expect(Booking.last.start_date.to_s).to eq("2023-04-18")
      expect(Booking.last.end_date.to_s).to eq("2023-04-20")
      expect(Booking.last.approved).to eq(false)
      # expect(Avail.find(property_id: 10, start_date: "2023-04-21".to_date, end_date: "2023-05-24".to_date))
    end

    it "returns logged in error page if user is not signed in" do
      sign_up
      @response = post("/bookings",
                       property_id: 10,
                       start_date: "2023-04-01",
                       end_date: "2023-04-03",
                       approved: false)
      check400
      expect(Booking.last.id).to eq(10)
      expect(@response.body).to include ("Log In Error")
    end

    it "date booked overlaps with another booking" do
      sign_up
      login
      post("/bookings",
           property_id: 4,
           start_date: "2023-04-01",
           end_date: "2023-04-03")
      post("/approve-reject/#{Booking.last.id}&true")
      @response = post("/bookings",
                       property_id: 4,
                       start_date: "2023-04-01",
                       end_date: "2023-04-03")
      expect(@response.status).to eq 302
    end
  end

  context "POST /approve-reject" do
    it "approves the request and updates the account page" do
      sign_up
      login
      post("/add-a-space?title=Snowden&address=Excelsior Rd, Western Ave, Cardiff CF14 3AT&description=Time waits for no man.
        Unless that man is Chuck Norris.&daily_rate=100&first_available=2023-01-18&last_available=2023-04-30")
      get("/log-out")
      second_sign_up
      second_log_in
      post("/bookings",
           property_id: 23,
           start_date: "2023-04-18",
           end_date: "2023-04-20",
           approved: false)
      expect(Avail.all.length).to eq 21
      get("/log-out")
      login
      @response = post("/approve-reject/#{Booking.last.id}&true")
      expect(@response.status).to eq 302
      expect(Booking.last.approved).to eq true
      expect(Booking.last.responded).to eq true
      expect(Avail.all.length).to eq 22
      expect(Avail.where(["property_id = ? and start_date = ? and end_date = ?", 10, "2023-03-15".to_date, "2023-04-17".to_date])).not_to eq nil
    end
  end
end
