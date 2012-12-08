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
    cookies[:timezone] = @timezone
    @zones  = HealthStatus::Web.timezones
    @status = HealthStatus::Model::Service.readonly.fetch_all_info(:end_time => Time.now.in_time_zone(@timezone))
    erb :index
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
    service = HealthStatus::Model::Service.find_or_initialize_by_name(service_name)
    application = service.applications.find_or_initialize_by_name(application_name)
    metric = application.metrics.find_or_initialize_by_name(metric_name)

    if service.new_record?
      service.status = params["status"]
      application.status = params["status"]
    elsif application.new_record?
      application.status = params["status"]
    end
    metric.status = params["status"]
    service.save!
    application.save!
    metric.save!

    application_status = nil
    application.metrics.each do |m|
      status = m.fetch_current_status
      if status.nil?
        application_status = status
      elsif application_status.nil?
        application_status = status
      elsif application_status <= status
        application_status = status
      end
    end
    if !application_status.nil? and application_status <= params["status"].to_i
      application.status = params["status"]
      application.save!
    end

    service_status = nil
    service.applications.each do |a|
      status = a.fetch_current_status
      if status.nil?
        service_status = status
      elsif service_status.nil?
        service_status = status
      elsif service_status <= status
        service_status = status
      end
    end
    if !service_status.nil? and service_status <= params["status"].to_i
      service.status = params["status"]
      service.save!
    end
    "OK"
  end

end
