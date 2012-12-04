require "health_status"
require "health_status/model"
require "erb"
require "cgi"

module HealthStatus::Web
  extend self

  def timezones
    zones = {}
    ActiveSupport::TimeZone.zones_map.each do |k, v|
      zones[v] = {
        "string" => k,
        "encode" => ERB::Util.u(k),
        "offset" => Time.now.in_time_zone(k).utc_offset,
      }
    end
    zones
  end

  def system_timezone
    timezones.values.each do |v|
      return CGI.unescape(v["string"]) if v["offset"] == Time.now.utc_offset
    end
  end

  def applications(timezone)
    applications = []
    HealthStatus::Model::Application.names_sort_by_status.each do |name|
      applications << get(name, timezone)
    end
    applications
  end

  def get(application, timezone)
    healthstatus = HealthStatus::Model::Application.find_or_initialize_by_name(application)
    current = Time.now.in_time_zone(timezone)

    res = {
      "application"    => healthstatus.name,
      "current_status" => healthstatus.fetch_current_status,
      "hourly"         => sort_history(healthstatus.fetch_hourly_status(:end_time => current)),
      "daily"          => sort_history(healthstatus.fetch_daily_status(:end_time => current)),
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
