require "health_status"
require "health_status/model"
require "health_status/web"
require "sinatra/base"
require "sinatra/activerecord"
require "sinatra/cookies"

class HealthStatus::App < Sinatra::Base

  class << self
    attr_accessor :database_path
  end

  helpers  Sinatra::Cookies
  register Sinatra::ActiveRecordExtension

  set :public_folder, File.expand_path("../../../public", __FILE__)
  set :views,         File.expand_path("../../../views", __FILE__)

  before do
    settings.database = "sqlite3:///#{HealthStatus::App.database_path}"
    ActiveRecord::Base.logger = nil
    HealthStatus::Model::Migrate.migrate
  end

  get '/' do
    @timezone = params["timezone"] || cookies[:timezone] || HealthStatus::Web.system_timezone
    cookies[:timezone] = @timezone
    @zones = HealthStatus::Web.timezones
    @apps  = HealthStatus::Web.applications(@timezone)
    erb :index
  end

  get '/api/v1/application' do
    HealthStatus::Model::Application.names_sort_by_status.to_json
  end

  get '/api/v1/application/:application' do |application|
    healthstatus = HealthStatus::Model::Application.find_or_initialize_by_name(application)
    time = Time.parse(params["time"] || Time.now.to_s)

    response = {
      :application    => healthstatus.name,
      :current_status => healthstatus.fetch_current_status,
      :hourly         => healthstatus.fetch_hourly_status(:end_time => time),
      :daily          => healthstatus.fetch_daily_status(:end_time => time),
    }

    response.to_json
  end

  post '/api/v1/application/:application' do |application|
    healthstatus = HealthStatus::Model::Application.find_or_initialize_by_name(application)
    raise unless params.has_key? "status"
    healthstatus.status = params["status"]
    healthstatus.save!
    "OK"
  end

  private

  def label_class(status)
    case status
    when 1
      "label label-success"
    when 2
      "label label-warning"
    when 3
      "label label-important"
    else
      "label"
    end
  end

  def row_class(status)
    case status
    when 1
      "success"
    when 2
      "warning"
    when 3
      "error"
    else
      ""
    end
  end

end
