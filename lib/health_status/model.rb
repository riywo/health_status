require "health_status"
require 'sinatra/activerecord'
require "sinatra/activerecord/rake"

require "tapp"

class HealthStatus::Model

  module AggregateStatus
    @@default_timezone = :utc
    @@half_hour = 30 * 60
    @@hour      = 60 * 60
    @@day       = 24 * @@hour

    def fetch_current_status
      current_status = nil

      if children.respond_to? :each
        children.each do |child|
          child_status = child.fetch_current_status
          if child_status and current_status
            current_status = child_status if current_status < child_status
          else
            current_status ||= child_status
          end
        end
      else ## Metric
        current_status = saved_at < floor_half_hour(Time.now) ? nil : status
      end

      current_status
    end

    def fetch_status_with_interval(interval, args = {})
      validate_args = validate_fetch_status(interval, args)
      interval_status = []

      if children.respond_to? :each
        children.each do |child|
          child_status = child.fetch_status_with_interval(interval, validate_args)
          if interval_status.size == 0
            interval_status = child_status.clone
          else
            interval_status.map! do |interval_data|
              child_data = child_status.shift
              if !interval_data[:status]
                child_data
              elsif !child_data[:status]
                interval_data
              else
                if interval_data[:status] < child_data[:status]
                  child_data
                else
                  interval_data
                end
              end
            end
          end
        end
      else ## Metric
        time = validate_args[:start_time]
        while time <= validate_args[:end_time]
          data = {
            :datetime => time,
            :status   => half_hour_statuses.where(:datetime => time..(time + interval - 1)).maximum(:status),
          }
          interval_status << data
          time += interval
        end
      end

      interval_status
    end

    def fetch_hourly_status(args = {})
      fetch_status_with_interval(@@hour, args)
    end

    def fetch_daily_status(args = {})
      fetch_status_with_interval(@@day, args)
    end

    def fetch_status(args = {})
      data = {
        :name           => name,
        :current_status => fetch_current_status,
        :hourly_status  => fetch_hourly_status(args),
        :daily_status   => fetch_daily_status(args),
      }
      if children.respond_to? :map
        data[children_name] = children.map do |child|
          child.fetch_status(args)
        end
      end
      data
    end

    private

    def validate_fetch_status(interval, args)
      end_time = args[:end_time]
      end_time ||= Time.now
      start_time = args[:start_time]
      start_time ||= end_time - (interval == @@day ? 7 * @@day : @@day)

      offset = start_time.utc_offset
      raise if offset != end_time.utc_offset
      raise if offset % @@half_hour != 0

      start_time = floor_hour(start_time)
      end_time   = floor_hour(end_time)
      { :start_time => start_time, :end_time => end_time }
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
  end

  class Service < ActiveRecord::Base
    include AggregateStatus

    has_many   :applications, :autosave => true

    def self.fetch_all_status(args = {})
      all.map do |service|
        service.fetch_status(args)
      end
    end

    def children_name
      :applications
    end

    def children
      applications
    end
  end

  class Application < ActiveRecord::Base
    include AggregateStatus

    belongs_to :service
    has_many   :metrics, :autosave => true

    def children_name
      :metrics
    end

    def children
      metrics
    end
  end

  class Metric < ActiveRecord::Base
    include AggregateStatus

    belongs_to :application
    has_many   :half_hour_statuses, :order => "datetime ASC"

    before_validation do self.saved_at = Time.now.utc end
    after_save :update_half_hour_status

    def children
      self
    end

    private

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
    belongs_to :metric
  end

  module Sort
    def self.names_sort_by_status
      all.sort do |a, b|
        a_status = a.fetch_current_status
        b_status = b.fetch_current_status
        if !a_status and !b_status
          a.name <=> b.name
        elsif !a_status
          1
        elsif !b_status
          -1
        else
          (b.fetch_current_status <=> a.fetch_current_status).nonzero? or
          a.name <=> b.name
        end
      end.map { |app| app.name }
    end
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
