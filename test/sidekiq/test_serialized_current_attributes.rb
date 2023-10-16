require "test_helper"

class Person
  include GlobalID::Identification

  NotFound = Class.new(StandardError)

  DESTROYED_ID = 123_456

  attr_reader :id

  def self.destroyed
    new(DESTROYED_ID)
  end

  def self.find(id)
    record = new(Integer(id))
    raise NotFound if record.destroyed?

    record
  end

  def initialize(id)
    @id = id
  end

  def destroyed?
    id == DESTROYED_ID
  end

  def to_global_id(_options = {})
    super app: "app"
  end

  def ==(other)
    other.is_a?(Person) && id.to_s == other.id.to_s
  end
end

class Current < ActiveSupport::CurrentAttributes
  attribute :person
end

class TestWorker
  include Sidekiq::Worker

  def perform(expected_id)
    raise "Current.person.id is not '#{expected_id}': #{Current.person.inspect}" if Current.person&.id != expected_id
  end
end

class Sidekiq::TestSerializedCurrentAttributes < Minitest::Test
  def setup
    Sidekiq::SerializedCurrentAttributes.persist("Current")
    # https://github.com/sidekiq/sidekiq/wiki/Testing#testing-server-middleware
    Sidekiq::Testing.server_middleware do |chain|
      chain.add Sidekiq::SerializedCurrentAttributes::Load, { "cattr" => "Current" }
    end
    Sidekiq::SerializedCurrentAttributes.discard_destroyed = false
  end

  def test_serializes_current_attributes
    Current.set(person: Person.new(20)) do
      TestWorker.perform_async(20)
    end

    job = TestWorker.jobs.first
    assert_equal job["cattr"], { "person" => { "_aj_globalid" => "gid://app/Person/20" } }
  end

  def test_deserializes_current_attributes
    Current.set(person: Person.new(20)) do
      TestWorker.perform_async(20)
    end

    # Will raise in case deserializing does not work
    TestWorker.drain
  end

  def test_discards_destroyed_records
    Sidekiq::SerializedCurrentAttributes.discard_destroyed = true

    Current.set(person: Person.destroyed) do
      TestWorker.perform_async(nil)
    end

    TestWorker.drain
  end

  def test_allows_disabling_discarding
    Current.set(person: Person.destroyed) do
      TestWorker.perform_async(nil)
    end

    assert_raises(ActiveJob::DeserializationError) { TestWorker.drain }
  end
end
