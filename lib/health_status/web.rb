require "health_status"
require "health_status/model"

module HealthStatus::Web
  extend self

  def get(application)
    healthstatus = HealthStatus::Model::Application.find_or_initialize_by_name(application)
    time = Time.now

    res = {
      "application" => healthstatus.name,
      "current"     => healthstatus.fetch_current_status(:time => time),
      "hourly"      => sort_history(healthstatus.fetch_hourly_status(:end_time => time)),
      "daily"       => sort_history(healthstatus.fetch_daily_status(:end_time => time)),
    }
  end

  def applications
    applications = []
    HealthStatus::Model::Application.pluck(:name).each do |name|
      applications << get(name)
    end
    applications
  end

  private

  def sort_history(history)
    res = []
    (0..history["datetime"].size-1).each do |i|
      res << {
        "datetime" => history["datetime"][i],
        "status"   => history["status"][i],
      }
    end
    res.reverse
  end
end
