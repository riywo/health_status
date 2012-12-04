require "health_status"
require 'sinatra/activerecord'
require "sinatra/activerecord/rake"

class HealthStatus::Model

  class Application < ActiveRecord::Base
    @@default_timezone = :utc
    has_many :half_hour_statuses, :order => "datetime ASC"
    before_validation :update_time
    after_save :update_half_hour_status

    @@half_hour = 30 * 60
    @@hour      = 60 * 60
    @@day       = 24 * @@hour

    def fetch_current_status
      if saved_at < floor_half_hour(Time.now)
        nil
      else
        status
      end
    end

    def fetch_hourly_status(args = {})
      start_time, end_time = validate_fetch_hourly_status(args)
      x = []
      y = []
      hour = start_time
      while hour <= end_time
        x << hour
        y << half_hour_statuses.where(:datetime => hour..(hour + @@hour - 1)).maximum(:status)
        hour += @@hour
      end
      { "datetime" => x, "status" => y }
    end

    def fetch_daily_status(args = {})
      start_time, end_time = validate_fetch_daily_status(args)
      x = []
      y = []
      day = start_time
      while day <= end_time
        x << day
        y << half_hour_statuses.where(:datetime => day..(day + @@day - 1)).maximum(:status)
        day += @@day
      end
      { "datetime" => x, "status" => y }
    end

    private

    def validate_fetch_hourly_status(args)
      args[:end_time]   ||= Time.now
      args[:start_time] ||= args[:end_time] - @@day

      offset = args[:start_time].utc_offset
      raise if offset != args[:end_time].utc_offset
      raise if offset % @@half_hour != 0

      start_time = floor_hour(args[:start_time])
      end_time   = floor_hour(args[:end_time])
      return start_time, end_time
    end

    def validate_fetch_daily_status(args)
      args[:end_time]   ||= Time.now
      args[:start_time] ||= args[:end_time] - (7 * @@day)

      offset = args[:start_time].utc_offset
      raise if offset != args[:end_time].utc_offset
      raise if offset % @@half_hour != 0

      start_time = floor_day(args[:start_time])
      end_time   = floor_day(args[:end_time])
      return start_time, end_time
    end

    def floor_half_hour(datetime)
      floor(datetime, @@half_hour)
    end

    def floor_hour(datetime)
      floor(datetime, @@hour)
    end

    def floor_day(datetime)
      floor(datetime, @@day)
    end

    def floor(datetime, seconds)
      offset = datetime.utc_offset
      Time.at(datetime.to_i - ((datetime.to_i + offset) % seconds).floor).localtime(offset)
    end

    def update_time
      now = Time.now.utc
      self.saved_at = now
    end

    def update_half_hour_status
      half_hour = floor_half_hour(self.saved_at)
      current = self.half_hour_statuses.find(:all, :conditions => { :datetime => half_hour } ).first
      if current
        current.status = status if current.status < status
        current.saved_at = self.saved_at
        current.save
      else
        half_hour_statuses.create(
          :status   => self.status,
          :datetime => half_hour,
          :saved_at => self.saved_at,
        )
      end
    end
  end

  class HalfHourStatus < ActiveRecord::Base
    @@default_timezone = :utc
    belongs_to :application
  end

  module Migrate
    extend Sinatra::ActiveRecordTasks
    extend self

    private

    def migrations_dir
      File.expand_path("../../../db/migrate", __FILE__)
    end
  end

end
