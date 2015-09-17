require 'json'
require 'csv'

NAME = 'choke'

def parse_data_samples
  csv_string = CSV.generate(force_quotes: true) do |csv|

    csv << ['angle', 'power', 'distance', 'our tank x', 'our tank y', 'hit point x', 'hit point y', 'highest point x', 'highest point y']

    Dir['data-sample/*.json'].each { |filename|
      result = parse_file(filename)
      csv << result if not result.empty?
    }
  end

  File.open('result.csv', 'w') { |file| file.write(csv_string) }
end

def parse_file(filename)
  if filename.include?('perform_move')
    response = JSON.parse(File.read(filename))

    our_outcome = response.fetch('outcome').find { |outcome|
      outcome.fetch('name') == NAME
    }

    return [] unless our_outcome

    _, _, angle, power, distance, _ = filename.split('_')

    tankPoint = our_outcome.fetch('tankMovement').first

    hitPoint = our_outcome.fetch('hitCoordinates')

    highestPoint = our_outcome.fetch('bulletTrajectory').max { |point| point.fetch('y') }

    [angle, power, distance, tankPoint['x'], tankPoint['y'], hitPoint['x'], hitPoint['y'], highestPoint['x'], highestPoint['y']]
  else
    []
  end
end

parse_data_samples
