require './template'

def handler event
  greeting = "An email scheduler built with faastRuby!"
  render html: template('index.html.erb', variables: { greeting: greeting })
end

def template(file, variables: {})
  Template.new(variables: variables).render(file)
end