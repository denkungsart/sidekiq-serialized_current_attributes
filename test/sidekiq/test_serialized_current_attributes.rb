require "test_helper"

class Person
  include GlobalID::Identification

  attr_reader :id

  def self.find(id)
    new(id)
  end

  def initialize(id)
    @id = id
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

  def perform
    raise "Current.person is not Person: #{Current.person.inspect}" unless Current.person.is_a?(Person)
  end
end

class Sidekiq::TestSerializedCurrentAttributes < Minitest::Test
  def setup
    Sidekiq::SerializedCurrentAttributes.persist("Current")
    # https://github.com/sidekiq/sidekiq/wiki/Testing#testing-server-middleware
    Sidekiq::Testing.server_middleware do |chain|
      chain.add Sidekiq::SerializedCurrentAttributes::Load, { "cattr" => "Current" }
    end
  end

  def test_serializes_current_attributes
    Current.set(person: Person.new(20)) do
      TestWorker.perform_async
    end

    job = TestWorker.jobs.first
    assert_equal job["cattr"], { "person" => { "_aj_globalid" => "gid://app/Person/20" } }
  end

  def test_deserializes_current_attributes
    Current.set(person: Person.new(20)) do
      TestWorker.perform_async
    end

    # Will raise in case deserializing does not work
    TestWorker.drain
  end
end
