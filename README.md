# Sidekiq::SerializedCurrentAttributes

Extends Sidekiq::CurrentAttributes to serialize values (such as activerecord objects).

## Installation

Install the gem and add to the application's Gemfile by executing:

```sh
bundle add sidekiq-serialized_current_attributes
```

## Usage

Automatically save and load any current attributes in the execution context so context attributes "flow" from Rails actions into any associated jobs. This can be useful for multi-tenancy, i18n locale, timezone, any implicit per-request attribute. See `ActiveSupport::CurrentAttributes`.

For multiple current attributes, pass an array of current attributes.

```ruby
# in your initializer
require "sidekiq/serialized_current_attributes"
Sidekiq::SerializedCurrentAttributes.persist("Myapp::Current")
# or multiple current attributes
Sidekiq::SerializedCurrentAttributes.persist(["Myapp::Current", "Myapp::OtherCurrent"])

# Discard destroyed records when serializing Current
Sidekiq::SerializedCurrentAttributes.discard_destroyed = true
```

## Changelog

### unreleased

- Reference global ::ActiveJob
- Prepend Load to server middleware

### 0.1.2 (2024-01-08)

- Change license to LGPL

### 0.1.1 (2023-10-16)

- Add option to discard destroyed records

### 0.1.0

- Initial release
