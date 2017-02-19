require "cuba"
require "mote"
require "cuba/contrib"
require "rack/protection"
require "shield"
require "letsfreckle"
require "dotenv"

Dotenv.load!

Cuba.plugin Cuba::Mote
Cuba.plugin Cuba::TextHelpers
Cuba.plugin Shield::Helpers

# Require all application files.
Dir["./config/**/*.rb"].each  { |rb| require rb }
Dir["./models/**/*.rb"].each  { |rb| require rb }
Dir["./routes/**/*.rb"].each  { |rb| require rb }

# Require all helper files.
Dir["./helpers/**/*.rb"].each { |rb| require rb }
Dir["./filters/**/*.rb"].each { |rb| require rb }

Cuba.use Rack::MethodOverride
Cuba.use Rack::Session::Cookie,
  key: "freckle-monthly-hours",
  secret: ENV['COOKIE_SECRET']

Cuba.use Rack::Protection
Cuba.use Rack::Protection::RemoteReferrer

Cuba.use Rack::Static,
  urls: %w[/js /css /img],
  root: "./public"

# Configure the client before fetching data.
LetsFreckle.configure do
  account_host ENV['ACCOUNT_HOST']
  username ENV['FRECKLE_USERNAME']
  token ENV['FRECKLE_TOKEN']
end

Cuba.define do
  persist_session!

  on root do
    @today = Date.today
    @begin_date = Date.new(@today.year, @today.month, 1)

    @array = []
    @entries = LetsFreckle::Entry.find(from: @begin_date.strftime, to: @today.strftime, projects: [PROJECT_ID])
    @hours_total = @entries.inject(0) {|sum, entry| sum + entry.minutes }.to_f / 60

    render("home",
           array: @array,
           entries: @entries,
           today: @today,
           begin_date: @begin_date,
           entries: @entries,
           hours_total: @hours_total,
           project_name: ENV['PROJECT_NAME'])
  end
end
