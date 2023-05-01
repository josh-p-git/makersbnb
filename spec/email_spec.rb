require "spec_helper"
require "pony"
require "email"
require "mail"
Pony.override_options = { :via => :test }

context "send_tag_email method" do
  include Mail::Matchers
  before(:each) do
    Mail::TestMailer.deliveries.clear
  end

  it "send email" do
    a = EmailTag.new
    a.send("orhan.khanbayov@hotmail.co.uk", "Email test", "testing") { is_expected.to have_sent_email }
  end

  it "sends email to correct person" do
    a = EmailTag.new
    a.send("orhan.khanbayov@hotmail.co.uk", "Email test", "testing") { is_expected.to have_sent_email.to("orhan.khanbayov@hotmail.co.uk") }
  end

  it "has correct subject" do
    a = EmailTag.new
    a.send("orhan.khanbayov@hotmail.co.uk", "Email test", "testing") { is_expected.to have_sent_email.with_subject("Email test") }
  end

  it "has correct subject" do
    a = EmailTag.new
    a.send("orhan.khanbayov@hotmail.co.uk", "Email test", "testing") { is_expected.to have_sent_email.with_body("testing") }
  end
end
