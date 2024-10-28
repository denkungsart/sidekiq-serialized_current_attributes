# frozen_string_literal: true

require "sidekiq"
require "active_support/current_attributes"
require "active_job/arguments"
require "active_support/core_ext/module/attribute_accessors"

require_relative "serialized_current_attributes/version"

# Code is pretty directly taken from https://github.com/sidekiq/sidekiq/blob/main/lib/sidekiq/middleware/current_attributes.rb, and adjusted so it uses ActiveJob argument serialization to support storing models.
module Sidekiq
  module SerializedCurrentAttributes
    mattr_accessor :discard_destroyed, default: false

    class Save
      include Sidekiq::ClientMiddleware

      def initialize(cattrs)
        @cattrs = cattrs
      end

      def call(_, job, _, _)
        @cattrs.each do |(key, strklass)|
          if !job.has_key?(key)
            attrs = serialize(strklass.constantize.attributes)
            # Retries can push the job N times, we don't
            # want retries to reset cattr. #5692, #5090
            job[key] = attrs if attrs.any?
          end
        end
        yield
      end

      def serialize(attributes)
        if Sidekiq::SerializedCurrentAttributes.discard_destroyed
          attributes = attributes.reject { |_, value| value.is_a?(GlobalID::Identification) && value.respond_to?(:destroyed?) && value.destroyed? }
        end

        serialized_values = ::ActiveJob::Arguments.serialize(attributes.values)
        attributes.keys.zip(serialized_values).to_h
      end
    end

    class Load
      include Sidekiq::ServerMiddleware

      def initialize(cattrs)
        @cattrs = cattrs
      end

      def call(_, job, _, &block)
        cattrs_to_reset = []

        @cattrs.each do |(key, strklass)|
          if job.has_key?(key)
            constklass = strklass.constantize
            cattrs_to_reset << constklass

            attributes = deserialize(job[key])
            attributes.each do |(attribute, value)|
              constklass.public_send("#{attribute}=", value)
            end
          end
        end

        yield
      ensure
        cattrs_to_reset.each(&:reset)
      end

      def deserialize(attributes)
        deserialized_values = ::ActiveJob::Arguments.deserialize(attributes.values)
        attributes.keys.zip(deserialized_values).to_h
      end
    end

    class << self
      def persist(klass_or_array, config = Sidekiq.default_configuration)
        cattrs = build_cattrs_hash(klass_or_array)

        config.client_middleware.add Save, cattrs
        config.server_middleware.prepend Load, cattrs
      end

      private

      def build_cattrs_hash(klass_or_array)
        if klass_or_array.is_a?(Array)
          {}.tap do |hash|
            klass_or_array.each_with_index do |klass, index|
              hash[key_at(index)] = klass.to_s
            end
          end
        else
          {key_at(0) => klass_or_array.to_s}
        end
      end

      def key_at(index)
        (index == 0) ? "cattr" : "cattr_#{index}"
      end
    end
  end
end
