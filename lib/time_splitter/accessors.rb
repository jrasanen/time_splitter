module TimeSplitter
  module Accessors
    def split_accessor(*attrs)
      options = attrs.extract_options!

      attrs.each do |attr|
        # Maps the setter for #{attr}_time to accept multipart-parameters for Time
        composed_of "#{attr}_time".to_sym, class_name: 'DateTime' if self.respond_to?(:composed_of)

        # Default instance of the attribute, used if setting an element of the
        # time attribute before the attribute was sent. Allows us to retrieve a
        # default value for +#{attr}+ to modify without explicitely overriding
        # the attr_reader. Defaults to a Time object with all fields set to 0.
        define_method("#{attr}_or_new") do
          self.send(attr) || options.fetch(:default, ->{ Time.new(0, 1, 1, 0, 0, 0, "+00:00") }).call
        end

        # Writers

        define_method("#{attr}=") do |value|
          self.send("#{attr}_date=", nil)
          self.send("#{attr}_hour=", nil)
          self.send("#{attr}_min=", nil)
          self.send("#{attr}_time=", nil)
          super(value)
        end

        define_method("#{attr}_date=") do |date|
          instance_variable_set("@#{attr}_date", date)
          return unless date.present?
          unless date.is_a?(Date) || date.is_a?(Time)
            begin
              if options[:date_format]
                date = Date.strptime(date.to_s, options[:date_format])
              else
                date = Date.parse(date.to_s)
              end
            rescue ArgumentError
              date = nil
            end
          end
          self.send("#{attr}=", self.send("#{attr}_or_new").change(year: date.year, month: date.month, day: date.day)) if date
        end

        define_method("#{attr}_hour=") do |hour|
          instance_variable_set("@#{attr}_hour", hour)
          return unless hour.present?
          self.send("#{attr}=", self.send("#{attr}_or_new").change(hour: hour, min: self.send("#{attr}_or_new").min))
        end

        define_method("#{attr}_min=") do |min|
          instance_variable_set("@#{attr}_min", min)
          return unless min.present?
          self.send("#{attr}=", self.send("#{attr}_or_new").change(min: min))
        end

        define_method("#{attr}_time=") do |time|
          instance_variable_set("@#{attr}_time", time)
          return unless time.present?

          unless time.is_a?(Date) || time.is_a?(Time)
            begin
              if options[:time_format]
                time = Time.strptime(time, options[:time_format])
              else
                time = Time.parse(time)
              end
            rescue ArgumentError
              time = nil
            end
          end
          self.send("#{attr}=", self.send("#{attr}_or_new").change(hour: time.hour, min: time.min)) if time
        end

        # Readers
        define_method("#{attr}_date") do
          if date = instance_variable_get("@#{attr}_date")
            date
          else
            date = self.send(attr).try :to_date
            instance_variable_set("@#{attr}_date", date && options[:date_format] ? date.strftime(options[:date_format]) : date)
          end
        end

        define_method("#{attr}_hour") do
          instance_variable_get("@#{attr}_hour") ||
            instance_variable_set("@#{attr}_hour", self.send(attr).try(:hour))
        end

        define_method("#{attr}_min") do
          instance_variable_get("@#{attr}_min") ||
            instance_variable_set("@#{attr}_min", self.send(attr).try(:min))
        end

        define_method("#{attr}_time") do
          if time = instance_variable_get("@#{attr}_time")
            time
          else
            time = self.send(attr)
            instance_variable_set("@#{attr}_time", time && options[:time_format] ? time.strftime(options[:time_format]) : time)
          end
        end
      end
    end
  end
end
