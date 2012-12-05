require "health_status"
require "health_status/model"
require "health_status/web"
require "sinatra/base"
require "sinatra/activerecord"
require "sinatra/cookies"

require "tapp"

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
    @zones  = HealthStatus::Web.timezones
    @status = HealthStatus::Model::Service.fetch_all_status(:end_time => Time.now.in_time_zone(@timezone)).tapp
    erb :index
  end

  post '/api/v2/:service/:application/:metric' do |service_name, application_name, metric_name|
    raise unless params.has_key? "status"
    service = HealthStatus::Model::Service.find_or_initialize_by_name(service_name)
    application = service.applications.find_or_initialize_by_name(application_name)
    metric = application.metrics.find_or_initialize_by_name(metric_name)

    metric.status = params["status"]

    service.save!
    application.save!
    metric.save!
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
