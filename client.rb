# requires rest-client installed: gem install rest-client

require 'rest-client'
require 'yaml'
require 'time'
require 'json'

SERVER = "http://10.12.202.141:9999"
TIMEOUT = 300000

TOURNAMENT_ID = "master"
AUTHORIZATION_TOKEN = "ResponsibleBrownMallardAlligator"

STD_ANGLE = 5.0
STD_MOVE = 30.0
POWER = 80
USERNAME = "choke"

TANK_SIZE = 30
LEFT_BOUND = -500
RIGHT_BOUND = 500
LOWER_BOUND = 0
UPPER_BOUND = 500

RESPONSES_DIR = './responses'

def save_response_to_file(action_name, response)
  filename = "#{action_name}_#{Time.now.to_i}"
  File.open("#{RESPONSES_DIR}/#{filename}.json", 'w') { |file| file.write(response) }
end

class RestClientWrapper < Struct.new(:tournamentId, :authorization)
  def post_move(params)
    url = "#{SERVER}/tournaments/#{tournamentId}/moves"
    headers = { 'Authorization' => authorization, 'content-type' => 'application/json' }
    RestClient::Request.execute(method: :post, payload: params.to_json, url: url, headers: headers, timeout: TIMEOUT)
  end

  def wait_for_game()
    url = "#{SERVER}/tournaments/#{tournamentId}/games/my/setup"
    headers = { 'Authorization' => authorization, 'content-type' => 'application/json' }
    RestClient::Request.execute(method: :get, url: url, headers: headers, timeout: TIMEOUT)
  rescue => e
    retry
  end
end

class Bot < Struct.new(:rest_client)
  def perform_move(angle, power, distance)
    payload = {
      "shotAngle" => "#{angle}",
      "shotPower" => "#{power}",
      "moveDistance" => "#{distance}"
    }

    response = rest_client.post_move(payload)
    JSON.parse(response).tap { |parsed_response|
      save_response_to_file('perform_move', parsed_response)
    }
  end

  def wait_for_game()
    response = rest_client.wait_for_game()
    JSON.parse(response).tap { |parsed_response|
      save_response_to_file('wait_for_game', parsed_response)
    }
  rescue => e
    retry
  end
end

class Tank < Struct.new(:name, :pos_x, :pos_y); end

class Tanks
  attr_reader :tanks

  def initialize(tanks)
    @tanks = []
    tanks.each do |tank|
      @tanks << Tank.new(tank["name"], tank["position"]["x"].to_f, tank["position"]["y"].to_f)
    end
  end

  def my_tank
    @tanks.find { |t| t.name == USERNAME }
  end
end


rest_client = RestClientWrapper.new(TOURNAMENT_ID, AUTHORIZATION_TOKEN)
bot = Bot.new(rest_client)

p "Bot initialized"

# move_direction = 1

SHOT_POWERS_TO_TEST = (0..100).to_a
turn = 0

while true

  game = bot.wait_for_game()

  p "--- Joining game #{game['name']}"

  game_in_progress = true
  while game_in_progress
    response = bot.perform_move(45, SHOT_POWERS_TO_TEST[turn % SHOT_POWERS_TO_TEST.size + 1], 0)

    tanks = Tanks.new(response["tanks"])

    p "My position x: #{tanks.my_tank.pos_x}"

    turn += 1
    game_in_progress = ! response['last']
  end

  p " --- game finished"
end
