# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "sidekiq/testing"
require "active_support/all"
require "active_job"
require "sidekiq/serialized_current_attributes"

require "minitest/autorun"
