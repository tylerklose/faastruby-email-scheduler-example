# Using faastRuby to send emails

This tutorial will show you how to create your first faastRuby function. It is extremely easy to get up and running and even easier to get your functions pushed out to production.

To illustrate how easy it is to get up and running, we will create a simple function that has one job: sending out recurring emails. We will use Mailgun to do some of the heavy-lifting for us with regards to sending out the actual emails themselves.

At first, we'll just serve up a static email that gets sent out whenever a specific endpoint gets hit. Then we'll evolve the function in two ways. 
1. We'll hit an external API of some sort to dynamically fetch content for the email
2. We'll use the built in scheduling functionality to schedule our emailing function to run daily at a predetermined time

Once we have this basic functionality set up, we will add an additional layer of complexity on top of this by storing a mailing list on a Redis instance rather than hardcoding the recipients in the function's code itself.

Here's a link to the [project on GitHub](https://github.com/tylerklose/faastruby-email-scheduler-example)!

## Steps
### faastRuby Setup
#### Installing the faastRuby CLI

```console
gem install faastruby
```

#### Create your faastRuby account
```console
faastruby signup
```

#### Create your faastRuby project
```console
faastruby new-project email-scheduler
```

### faastRuby Basics

#### Working with faastRuby Local
```console
cd email-scheduler
faastruby local
```

Now open up localhost:3000 in your browser. You should see something like this:
![Screenshot of boilerplate landing page](https://take.ms/5vBtb)

**Brief explanation as to what faastRuby Local does. Go into detail about watchdog and whatnot**

#### File Structure

Now let's take a quick look at `functions/root/handler.rb`. If you're familiar with Rails, some of this may look familiar to you.

```ruby
require './template'

def handler event
  greeting = "Welcome to FaaStRuby Local!"
  render html: template('index.html.erb', variables: { greeting: greeting })
end

def template(file, variables: {})
  Template.new(variables: variables).render(file)
end
```

`def handler` is synonymous with a controller action in Rails. The `render` statement in faastRuby also behaves similarly to the render statement in Rails. One key thing to note is the inclusion of `def template` and the use of `variables` as opposed to `locals`.

Let's change to the string assigned to `greeting`:
```ruby
def handler event
  greeting = "An email scheduler built with faastRuby!"
  render html: template('index.html.erb', variables: { greeting: greeting })
end
```

Refresh the page and now you should see our new greeting rendered.

Now let's take a look at `index.html.erb`, this is where our `greeting` variable has been made available.

```html
<div class="content">
  <h1 class="text-center"><%= @greeting %></h1>
  <p class="text-center">To customize this page, edit the function 'root'.</p>
</div>
  ```

This is also where you'd link to any external stylesheets or JavaScript files you may want to include for rendering this specific page. These assets live in the `public/assets/` directory at the root of the project.

```html
<link href="/assets/stylesheets/main.css" rel="stylesheet">
...
<!-- JavaScript -->
<script src="/assets/javascripts/main.js"></script>
```

#### Generating our first function
When you create a new project via the cli `faastruby new-project <project-name>` you are automatically provided two functions: `root` and `catch-all`. The `root` function is invoked when your app is called without an endpoint (e.g. `localhost:3000/`). The `catch-all` function is invoked when an endpoint without a function is hit (e.g. `localhost:3000/this-function-doesnt-exist`)

Let's try going to `localhost:3000/send-email` and see this in action. You should see a big ol' header that simply states "Page Not Found." As you may have guessed, this is a perfect place to handle 404 errors.

Now let's create a send-email function via the CLI:
**Note to selves: it felt really unnatural to have to specify the functions directory when generating a new function**

**The alternative is to create the directory and the handler.rb file through the text editor**

```console
faastruby new functions/send-email
+ d send-email
+ d send-email/spec
+ f send-email/spec/spec_helper.rb
+ f send-email/spec/handler_spec.rb
+ f send-email/README.md
+ f send-email/Gemfile
+ f send-email/handler.rb
+ f send-email/faastruby.yml
✔ Installing gems...
```

Let's unpack some of what just happened. faastRuby is generating some boilerplate code for you to work with. Every function will have its own test suite, its own Gemfile, and its own `faastruby.yml` which we'll discuss in detail later.

**Is this self-explanatory? Is there anything we should discuss in detail right here?**

Now if we try going to `localhost:3000/send-email` again, we get a different result as shown by the `render` function in `handler` located in `functions/send-email/handler.rb`:
```ruby
def handler event
  # ...
  render text: "Hello, World!\n"
end
```

### Mailgun Setup

Instead of simply rendering text that says "Hello, World!" we'll want to fire off an email of some sort. To do this, we'll be relying on a transactional email API service. In this example, we'll be using [Mailgun](https://www.mailgun.com). They give you 10,000 emails free every month and that's more than we'll need for this project. So go ahead and create yourself an account if you don't have one already. Grab your API key from the Settings menu inside the dashboard and let's get going!

When you created your faastRuby project, you may have noticed that it generated a `.gitignore`'d file called `secrets.yml`. This is where we're going to put our API key for Mailgun.

When running `faastruby local`, the environment that the keys will be pulled out of will be `stage`.

Your `secrets.yml` file should now look something like this:
```yml
secrets:
  stage:
    send-email:
      mailgun:
        api_key: Private-API-Key
```

If you make your `functions/send-email/handler.rb` file look something like this:
```ruby
require 'oj' # Use Oj for faster JSON

def handler(event)
  context = Oj.load(event.context)
  render text: context["mailgun"]["api_key"]
end
```
and refresh the page, you should now see your Mailgun API key rendered on the page as plaintext.

Great so now we just have to have our `send-email` function well... send an email using Mailgun. For that we can get a little help from the`mailgun-ruby` gem. Simply add it to `functions/send-email/Gemfile`:

```ruby
source 'https://rubygems.org'

gem 'mailgun-ruby'
...
```

and save your file. faastRuby will pick up on the change and run a fresh `bundle install` for you:
```console
2019-05-22 06:57:18 -0400 | Running: cd send_email && bundle install
---
Fetching gem metadata from https://rubygems.org/.............
Fetching gem metadata from https://rubygems.org/.
Resolving dependencies...
...
Using faastruby 0.5.26
Fetching mailgun-ruby 1.1.11
Installing mailgun-ruby 1.1.11
...
Bundle complete! 4 Gemfile dependencies, 58 gems now installed.
Use `bundle info [gemname]` to see where a bundled gem is installed.
---
2019-05-22 06:57:21 -0400 | Gems from Gemfile 'send_email/Gemfile' were installed in your local machine.
---
```

**Looks like I needed to associate a domain to send the emails from, cause I couldn't quite figure out how to do it without it. I'll have to revisit this because it would create some friction that might make someone uninterested in proceeding forward.**

You'll need to put a credit card on file with them cause you need to "upgrade" in order to use a custom domain. After that, head over to the Domains section in the dashboard. Add your domain with the subdomain `mg`. They suggest you dedicate a subdomain for this service.

You'll need to add two DNS records at your DNS provider. Both records are of type `TXT`.  One record is for the domain including the subdomain (`mg.domain.com`) you just set above as well and another for `mx._domainkey.mg.tylerklose.com`.

(Note: DNS propogation can take some time so if you click Verify DNS Settings and it's coming up as unverified, go take a quick break and by the time you're done it should be good to go (assuming you added the records correctly 😅))

Now back to `functions/send-email/handler.rb`. Your file should look something like this:

```ruby
require 'json'
require 'mailgun-ruby'

def handler event
  require 'oj' # Use Oj for faster JSON
  api_key = context["mailgun"]["api_key"]

  mg_client = Mailgun::Client.new(api_key)

  # Define your message parameters
  message_params =  { from: 'from@yourdomain.com',
                      to:   'your@email.com',
                      subject: 'faastRuby & Mailgun!',
                      text:    'It is really easy to send a message with faastRuby and Mailgun!'
                    }

  # Send your message through the client
  mg_client.send_message 'mg.yourdomain.com', message_params

  render text: "Email sent!"
end
```

Visit `localhost:3000/send-email` and check your inbox!

Now we want to schedule this to send emails periodically. I'll start by sending me these emails every morning shortly before I usually wake up: 5:30AM. We can set the frequency in which the endpoint is hit by editing `functions/send-email/faastruby.yml`

`faastruby` uses the `fugit` gem to help parse the frequency provided in `faastruby.yml`.

You can see what kind of options you have for `when:` [here](https://github.com/floraison/fugit#fugitparses).

I'm going to set mine to a specific time a minute or two after the current time to test the functionality. Here's the resulting config:
```yml
---
cli_version: 0.5.26
name: send-email
before_build: []
runtime: ruby:2.6

schedule:
  morning_email:
    when: every day at 22:45 America/New_York
```
**If a timezone is not specified, UTC will be used**

Once I've confirmed it worked, I will schedule the job to run at the desired time:
```yml
---
cli_version: 0.5.26
name: send_email
before_build: []
runtime: ruby:2.6

schedule:
  morning_email:
    when: every day at 05:45 America/New_York
```
### Fetching data from an external API (Optional)
In this email, I'd like to send myself some weather forecast data. To do so, I'm going to use the [Dark Sky API](https://darksky.net/dev).

```console
faastruby new functions/weather
```

Once your function has been created, your `functions/weather/handler.rb` should look something like this:
```ruby
require 'oj'
require 'forecast_io'

def handler(event)
  context = Oj.load(event.context)
  api_key = context["dark_sky"]["api_key"]

  ForecastIO.api_key = api_key

  latitude = '40.75972'
  longitude = '-73.991829'

  forecast = ForecastIO.forecast(latitude, longitude, options = {}).to_json
  render json: forecast
end
```

For this to work you'll need the following in your `functions/weather/Gemfile`:
```ruby
source 'https://rubygems.org'

gem 'forecast_io'
...
```

You will also need to provide your Dark Sky API key in our `secrets.yml` file. Mine looks something like this:
```yml
secrets:
  prod:
    send-email:
      mailgun:
        api_key: mailgun-api-key
    weather:
      dark_sky:
        api_key: dark-sky-api-key
        
  stage:
    send-email:
      mailgun:
        api_key: mailgun-api-key
    weather:
      dark_sky:
        api_key: dark-sky-api-key
```

Let's verify that the `weather` function does what we expect by going to `localhost:3000/weather. You should see a JSON blob rendered on the page.

Without going into detail with what I'm doing with the data, the method below illustrates how we call functions from within functions in faastRuby:
```ruby
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
    OpenStruct.new(Oj.load(response.value)['currently'])
  end
  # If you don't need to use callbacks:
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
```

What's happening here is we are importing our `weather` function. Then we're using the native way of calling that function from within a function via `Weather.call`. Providing a block to this call creates an asynchronous request with a callback function:
```ruby
  forecast = Weather.call do |response|
    OpenStruct.new(Oj.load(response.value)['currently'])
  end
```

This request is running in the background asynchrously while the rest of our `handler` method is free to go about its business. The first iteration of the loop that builds up the HTML content for our email will be blocked until the async request returns and sets the contents of `forecast`:
```ruby
  info_map.each do |info|
    # Because you used a callback, calling forecast here will block
    # the first iteration until the request returns
    html << "<div>#{info[:label]}: #{forecast[info[:key]]}</div>"
  end
```

Putting this all together with a `Mailgun::MessageBuilder` object, our end result for `functions/send-email/handler.rb` should look something like this:
```ruby
require 'oj' # Use Oj for faster JSON

require 'mailgun-ruby'

def handler(event)
  context = Oj.load(event.context)
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
  mb_obj.from("update@yourdomain.com", {"first"=>"Some", "last" => "Name"})

  # Define a to recipient.
  mb_obj.add_recipient(:to, "tylerklose@gmail.com", {"first" => "Tyler", "last" => "Klose"})

  # Define the subject.
  mb_obj.subject("Here's your update for today!")

  # Define the body of the message.
  mb_obj.body_html("<html><body>#{html}</body></html>")

  mb_obj
end
```

Now when you visit `localhost:3000/send-email` you should see "Email sent!" rendered on the page and you should expect an email in your inbox containing some weather data!

Here's a link to the [project on GitHub](https://github.com/tylerklose/faastruby-email-scheduler-example)!