# HealthStatus

API server to store and visualize applications' health status.

## Installation

Add this line to your application's Gemfile:

    gem 'health_status'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install health_status

## Usage

    $ health_status_server -d /path/to/sqlite.db

    $ curl -v -d "status=1" localhost:5678/service1/application1/metric1
    $ curl -v -d "status=2" localhost:5678/service1/application1/metric2

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
