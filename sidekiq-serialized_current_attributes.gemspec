# frozen_string_literal: true

require_relative "lib/sidekiq/serialized_current_attributes/version"

Gem::Specification.new do |spec|
  spec.name = "sidekiq-serialized_current_attributes"
  spec.version = Sidekiq::SerializedCurrentAttributes::VERSION
  spec.authors = ["Fabian Schwahn"]
  spec.email = ["fabian.schwahn@gmail.com"]

  spec.summary = "Serialize CurrentAttributes for Sidekiq"
  spec.homepage = "https://github.com/denkungsart/sidekiq-serialized_current_attributes"
  spec.license = "LGPL-3.0-only"
  spec.required_ruby_version = ">= 2.6.0"

  spec.metadata["homepage_uri"] = spec.homepage

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .circleci appveyor Gemfile])
    end
  end
  spec.require_paths = ["lib"]

  spec.add_dependency "activejob"
  spec.add_dependency "activesupport"
  spec.add_dependency "sidekiq"
end
