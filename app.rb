require 'sinatra'
require 'pry'
require 'betfair'
require 'active_support/core_ext/numeric/time'

application_id = ENV["APPLICATION_ID"] or raise("No APPLICATION_ID env given")
user_name = ENV["USER_NAME"] or raise("No USER_NAME env given")
password = ENV["PASSWORD"] or raise("No PASSWORD env given")

set :bind, "0.0.0.0"

get "/" do
  client = Betfair::Client.new("X-Application" => application_id)
  client.interactive_login(user_name, password)
  markets = client.list_market_catalogue({
    filter: {
      eventTypeIds: ["6422"],
      marketTypeCodes: ["MATCH_ODDS"],
      marketStartTime: {
        from: Time.now.beginning_of_day.iso8601,
        to: 7.days.from_now.end_of_day.iso8601
      },
      marketCountries: ["GB", "IRE"]
    },
    maxResults: 200,
    marketProjection: [
      "MARKET_START_TIME",
      "RUNNER_METADATA",
      "RUNNER_DESCRIPTION",
      "EVENT_TYPE",
      "EVENT",
      "COMPETITION"
    ]
  })

  books = client.
    list_market_book(marketIds: markets.map { |m| m["marketId"] })
    .each_with_object({}) do |market, memo|
      memo[market["marketId"]] = market
    end

  content_type :json
  markets.map do |market|
    odds = books[market["marketId"]]
    {
      marketId: market["marketId"],
      event: market["event"]["name"],
      start: market["marketStartTime"],
      odds: odds["runners"].map {|runner| runner["lastPriceTraded"] }
    }
  end.to_json
end
