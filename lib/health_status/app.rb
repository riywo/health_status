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

  helpers  Sinatra::Cookies, ERB::Util
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
    @zones  = HealthStatus::Web.timezones
    erb :index
  end

  get '/api/v2/' do
    HealthStatus::Model::Service.readonly.fetch_all_info().to_json
  end

  get '/api/v2/:service' do |service_name|
    args = {}
    args[:end_time] = Time.now.in_time_zone(params["timezone"])
    args[:with_status] = true
    service = HealthStatus::Model::Service.find_by_name(service_name)
    service.fetch_info(args).to_json
  end

  get '/api/v2/:service/:application' do |service_name, application_name|
    Time.zone = params["timezone"]
    args = {}
    args[:end_time] = Time.now.in_time_zone(params["timezone"])
    args[:with_status] = true
    application = HealthStatus::Model::Service.find_by_name(service_name).applications.find_by_name(application_name)
    application.fetch_info(args).to_json
  end

  get '/api/v2/:service/:application/:metric' do |service_name, application_name, metric_name|
    Time.zone = params["timezone"]
    args = {}
    args[:end_time] = Time.now.in_time_zone(params["timezone"])
    args[:with_status] = true
    metric = HealthStatus::Model::Service.find_by_name(service_name).applications.find_by_name(application_name).metrics.find_by_name(metric_name)
    metric.fetch_info(args).to_json
  end

  post '/api/v2/:service/:application/:metric' do |service_name, application_name, metric_name|
    raise unless params.has_key? "status"
    HealthStatus::Model::Service.save_metric(service_name, application_name, metric_name, params["status"])
    "OK"
  end

  delete '/api/v2/:service' do |service_name|
    HealthStatus::Model::Service.find_by_name(service_name).destroy
    "OK"
  end

  delete '/api/v2/:service/:application' do |service_name, application_name|
    HealthStatus::Model::Service.find_by_name(service_name).applications.find_by_name(application_name).destroy
    "OK"
  end

  delete '/api/v2/:service/:application/:metric' do |service_name, application_name, metric_name|
    HealthStatus::Model::Service.find_by_name(service_name).applications.find_by_name(application_name).metrics.find_by_name(metric_name).destroy
    "OK"
  end

end
