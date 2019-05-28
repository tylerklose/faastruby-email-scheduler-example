require 'json'

require 'forecast_io'

def handler(event)
  context = JSON.parse(event.context)
  api_key = context["dark_sky"]["api_key"]

  ForecastIO.api_key = api_key

  latitude = '40.75972'
  longitude = '-73.991829'

  forecast = ForecastIO.forecast(latitude, longitude, options = {}).to_json
  render json: forecast
end