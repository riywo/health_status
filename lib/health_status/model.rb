require "health_status"
require 'sinatra/activerecord'
require "sinatra/activerecord/rake"

class HealthStatus::Model

  module AggregateStatus
    @@default_timezone = :utc
    @@half_hour = 30 * 60
    @@hour      = 60 * 60
    @@day       = 24 * @@hour

    def fetch_current_status
      if saved_at < floor_half_hour(Time.now.utc)
        nil
      else
        status
      end
    end

    def fetch_saved_at(args)
      end_time = args[:end_time]
      end_time ||= Time.now
      Time.at(saved_at.to_i).localtime(end_time.utc_offset)
    end

    def fetch_status_with_interval(interval, args = {})
      validate_args = validate_fetch_status(interval, args)
      interval_status = []
      time = validate_args[:start_time]
      while time <= validate_args[:end_time]
        data = {
          :datetime => time,
          :status   => self_half_hour_statuses.where(:datetime => time..(time + interval - 1)).maximum(:status),
        }
        interval_status << data
        time += interval
      end
      interval_status
    end

    def fetch_hourly_status(args = {})
      fetch_status_with_interval(@@hour, args)
    end

    def fetch_daily_status(args = {})
      fetch_status_with_interval(@@day, args)
    end

    def fetch_info(args = {})
      depth = args[:depth].nil? ? 0 : args[:depth]
      data = {
        :id             => id,
        :name           => name,
        :current_status => fetch_current_status,
        :saved_at       => fetch_saved_at(args),
      }
      if args[:with_status]
        data[:hourly_status] = fetch_hourly_status(args)
        data[:daily_status]  = fetch_daily_status(args)
      end

      data[:service_id] = service.id if respond_to? :service
      if respond_to? :application
        data[:service_id] = application.service.id
        data[:application_id] = application.id
      end

      if children.respond_to? :map and depth > 0
        data[children_name] = children.map do |child|
          args[:depth] = depth - 1
          child.fetch_info(args)
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

      start_time = floor(start_time, interval)
      end_time   = floor(end_time, interval)
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

    def update_half_hour_status
      half_hour = floor_half_hour(self.saved_at)
      current = self.self_half_hour_statuses.find(:all, :conditions => { :datetime => half_hour } ).first
      if current
        current.status = status if current.status < status
        current.saved_at = self.saved_at
        current.save
      else
        self_half_hour_statuses.create(
          :status   => self.status,
          :datetime => half_hour,
          :saved_at => self.saved_at,
        )
      end
    end
  end

  class Service < ActiveRecord::Base
    include AggregateStatus

    has_many   :applications
    has_many   :service_half_hour_statuses, :order => "datetime ASC"

    before_validation do self.saved_at = Time.now.utc end
    after_save :update_half_hour_status

    def self.fetch_all_info(args = {})
      all.map do |service|
        args[:depth] = 2
        service.fetch_info(args)
      end
    end

    def self.save_metric(service_name, application_name, metric_name, status)
      service     = find_or_initialize_by_name(service_name)
      application = service.applications.find_or_initialize_by_name(application_name)
      metric      = application.metrics.find_or_initialize_by_name(metric_name)

      if service.new_record?
        service.status = status
        application.status = status
      elsif application.new_record?
        application.status = status
      end
      metric.status = status
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
      if !application_status.nil? and application_status <= status.to_i
        application.status = status
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
      if !service_status.nil? and service_status <= status.to_i
        service.status = status
        service.save!
      end
    end

    def self_half_hour_statuses
      service_half_hour_statuses
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
    has_many   :metrics
    has_many   :application_half_hour_statuses, :order => "datetime ASC"

    before_validation do self.saved_at = Time.now.utc end
    after_save :update_half_hour_status

    def self_half_hour_statuses
      application_half_hour_statuses
    end

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
    has_many   :metric_half_hour_statuses, :order => "datetime ASC"

    before_validation do self.saved_at = Time.now.utc end
    after_save :update_half_hour_status

    def self_half_hour_statuses
      metric_half_hour_statuses
    end

    def children
      self
    end

  end

  class ServiceHalfHourStatus < ActiveRecord::Base
    @@default_timezone = :utc
    belongs_to :service
  end

  class ApplicationHalfHourStatus < ActiveRecord::Base
    @@default_timezone = :utc
    belongs_to :application
  end

  class MetricHalfHourStatus < ActiveRecord::Base
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
