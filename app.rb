require 'sinatra'
require 'pry'
require 'betfair'
require 'active_support/core_ext/numeric/time'

APPLICATION_ID = ENV["APPLICATION_ID"] or raise("No APPLICATION_ID env given")
USER_NAME = ENV["USER_NAME"] or raise("No USER_NAME env given")
PASSWORD = ENV["PASSWORD"] or raise("No PASSWORD env given")

set :bind, "0.0.0.0"

def get_client
  client = Betfair::Client.new("X-Application" => APPLICATION_ID)
  client.interactive_login(USER_NAME, PASSWORD)
  client
end

get "/" do
  client = get_client
  markets = client.list_market_catalogue({
    filter: {
      competitionIds: ["5614746"],
      marketTypeCodes: ["MATCH_ODDS"],
      marketStartTime: {
        from: Time.now.beginning_of_day.iso8601,
        to: 7.days.from_now.end_of_day.iso8601
      },
      inPlayOnly: false
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

  books = client
    .list_market_book(marketIds: markets.map { |m| m["marketId"] })
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
      odds: odds["runners"].each_with_object({}) do |runner, memo|
        body = {
          name: market["runners"].find { |market_runner| market_runner["selectionId"] == runner["selectionId"] }["runnerName"],
          odds: runner["lastPriceTraded"]
        }

        memo[runner["selectionId"]] = body
      end
    }
  end.to_json
end

get "/winner" do
  client = get_client
  match_ids = Array(params[:market_ids].split(','))
  matches = match_ids.map do |match_id|
    client.list_market_book({
      marketIds: Array(match_id)
    }).first
  end
  matches.map do |match|
    puts match
    winner = match["runners"].find { |runner| runner["status"] == "WINNER" }
    {
      marketId: match["marketId"],
      winner: winner ? winner["selectionId"] : nil
    }
  end.to_json
end
