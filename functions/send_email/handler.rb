require 'json'

require 'mailgun-ruby'
require 'pry'

def handler event
  context = JSON.parse(event.context)
  mail_api_key = context["mailgun"]["api_key"]
  mg_client = Mailgun::Client.new(mail_api_key)

  weather_html = fetch_weather

  email = build_email(weather_html)
  mg_client.send_message("mg.tylerklose.com", email)

  render text: "Email sent!\n"
end

def fetch_weather
  response = RestClient::Request.execute(
    method: :get,
    url: "localhost:3000/weather",
    headers: { content_type: 'application/json' }
  )

  forecast = OpenStruct.new(JSON.parse(response.body)['currently'])
  html = ""
  info_map = [{ key: 'summary', label: 'Summary' }, { key: 'temperature', label: 'Current Temperature' }, { key: 'uvIndex', label: 'UV Index' }]
  info_map.each do |info|
    html << "<div>#{info[:label]}: #{forecast[info[:key]]}</div>"
  end

  html
end

def build_email(html)
  mb_obj = Mailgun::MessageBuilder.new()

  # Define the from address.
  mb_obj.from("update@tylerklose.com", {"first"=>"TK", "last" => "Updates"})

  # Define a to recipient.
  mb_obj.add_recipient(:to, "tylerklose@gmail.com", {"first" => "Tyler", "last" => "Klose"})

  # Define the subject.
  mb_obj.subject("Here's your update for today!")

  # Define the body of the message.
  mb_obj.body_html("<html><body>#{html}</body></html>")

  mb_obj
end
