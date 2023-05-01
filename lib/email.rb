require "pony"

class EmailTag
  def send(send, subject, body)
    Pony.options = { :from => "rspeccowboysbnb@gmail.com", :via => :smtp, :via_options => {
      :address => "smtp.gmail.com",
      :port => "587",
      :enable_starttls_auto => true,
      :user_name => "rspeccowboysbnb@gmail.com",
      :password => "iiowutxmymyjlasv",
      :authentication => :plain,
      :domain => "localhost.localdomain",
    } }

    Pony.mail(:to => send, :subject => subject, :body => body)
  end
end
