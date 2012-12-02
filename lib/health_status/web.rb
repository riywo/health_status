require "health_status"
require "health_status/model"
require "erb"

module HealthStatus::Web
  extend self

  def timezones
    zones = {}
    ActiveSupport::TimeZone.zones_map.each do |k, v|
      zones[v] = {
        "string" => ERB::Util.u(k),
        "offset" => Time.now.in_time_zone(k).utc_offset,
      }
    end
    zones
  end

  def applications(timezone)
    applications = []
    HealthStatus::Model::Application.pluck(:name).each do |name|
      applications << get(name, timezone)
    end
    applications
  end

  def get(application, timezone)
    healthstatus = HealthStatus::Model::Application.find_or_initialize_by_name(application)
    current = Time.now.in_time_zone(timezone)

    res = {
      "application" => healthstatus.name,
      "current"     => healthstatus.fetch_current_status(:time => current),
      "hourly"      => sort_history(healthstatus.fetch_hourly_status(:end_time => current)),
      "daily"       => sort_history(healthstatus.fetch_daily_status(:end_time => current)),
    }
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
