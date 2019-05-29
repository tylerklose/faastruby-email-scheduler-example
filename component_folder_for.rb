require 'pathname'

# 2.6.1 :001 > puts Dir['*/**/handler.rb']
# functions/root/handler.rb
# functions/weather/handler.rb
# functions/catch-all/handler.rb
# functions/send_email/handler.rb

def component_folder_for(path)
  return path.to_s if Dir["#{path.parent.to_s}/**/handler.rb"].size > 1
  component_folder_for(path.parent)
end

filepath = "functions/weather/handler.rb"
puts component_folder_for(Pathname.new(filepath))

filepath = "functions/root/handler.rb"
puts component_folder_for(Pathname.new(filepath))

filepath = "functions/catch-all/handler.rb"
puts component_folder_for(Pathname.new(filepath))

filepath = "functions/send_email/handler.rb"
puts component_folder_for(Pathname.new(filepath))

# ruby component_folder_for.rb 
# functions/weather
# functions/root
# functions/catch-all
# functions/send_email