require "health_status"
require "health_status/model"
require "health_status/web"
require "sinatra/base"
require "sinatra/activerecord"

class HealthStatus::App < Sinatra::Base
  register Sinatra::ActiveRecordExtension

  set :public_folder, File.expand_path("../../../public", __FILE__)
  set :views,         File.expand_path("../../../views", __FILE__)

  get '/' do
    @apps = HealthStatus::Web.applications
    erb :index
  end

  get '/api/v1/application' do
    HealthStatus::Model::Application.pluck(:name).to_json
  end

  get '/api/v1/application/:application' do |application|
    healthstatus = HealthStatus::Model::Application.find_or_initialize_by_name(application)
    time = Time.parse(params["time"] || Time.now.to_s)

    response = {
      :application => healthstatus.name,
      :current     => healthstatus.fetch_current_status(:time => time),
      :hourly      => healthstatus.fetch_hourly_status(:end_time => time),
      :daily       => healthstatus.fetch_daily_status(:end_time => time),
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

  def label_name(status)
    case status
    when 1
      "success"
    when 2
      "warning"
    when 3
      "important"
    else
      "inverse"
    end
  end

  def row_name(status)
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
