require 'oj' # Use Oj for faster JSON

require 'mailgun-ruby'
# require 'pry' # Don't ship pry to the cloud. Maybe we should bake that in Local

def handler event
  context = JSON.parse(event.context)
  mail_api_key = context["mailgun"]["api_key"]
  mg_client = Mailgun::Client.new(mail_api_key)

  weather_html = fetch_weather

  email = build_email(weather_html)
  mg_client.send_message("mg.tylerklose.com", email)

  render text: "Email sent!\n"
end

# Use the native way of calling a function from another function
require_function "weather", as: "Weather"
def fetch_weather
#   response = RestClient::Request.execute(
#     method: :get,
#     url: "localhost:3000/weather",
#     headers: { content_type: 'application/json' }
#   )
  # Async call with a callback. `forecast` will be equal what the block returns
  # once the request is back
  forecast = Weather.call do |response|
    # Use Oj
    OpenStruct.new(Oj.load(response.value)['currently'])
  end
  # You don't need to use callbacks:
  # weather = Weather.call
  # Do other stuff while you wait for the response from `weather`
  html = ""
  info_map = [{ key: 'summary', label: 'Summary' }, { key: 'temperature', label: 'Current Temperature' }, { key: 'uvIndex', label: 'UV Index' }]
  # Here you would parse the response if you had chosen to not use a callback.
  # This would be a blocking call:
  # forecast = OpenStruct.new(Oj.load(weather.value)['currently'])
  info_map.each do |info|
    # Because you used a callback, calling forecast here will block
    # the first iteration until the request returns
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
