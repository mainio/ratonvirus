# <img alt="Ratonvirus" src="https://raw.githubusercontent.com/mainio/ratonvirus/master/ratonvirus.png" width="600">

Rails antivirus made easy.
Developed by [Mainio Tech](https://www.mainiotech.fi/).

[![Build Status](https://travis-ci.org/mainio/ratonvirus.svg?branch=master)](https://travis-ci.org/mainio/ratonvirus)
[![codecov](https://codecov.io/gh/mainio/ratonvirus/branch/master/graph/badge.svg)](https://codecov.io/gh/mainio/ratonvirus)

Ratonvirus allows your Rails application to rat on the viruses that your users
try to upload to your site. This works through Rails validators that you can
easily attach to your models.

The purpose of Ratonvirus is to act as the glue that binds your Rails
application to a virus scanner and file storage engine of your choise.

Setting up scanning for files attached to models:

```ruby
class Model < ApplicationRecord
  # ...
  validates :file, antivirus: true
  # ...
end
```

Running manual scans:

```ruby
puts "File contains a virus" if Ratonvirus.scanner.virus?("/path/to/file.pdf")
```

Manual scanning works e.g. for file uploads, file object and file paths.

Ratonvirus works with Active Storage out of the box. Support for CarrierWave is
also built in, assuming you already have CarrierWave as a dependency.

## When to use this?

This gem can be handy if you want to:

- Scan files for viruses in Ruby, especially in Rails
- Make the scanning logic agnostic of the
  * scanner implementation (e.g. ClamAV)
  * file storage (e.g. Active Storage, CarrierWave, no storage engine)
- Separate testing code for the scanner implementation or the file storage
  cleanly into its own place.

## Prerequisites

There is no fully Ruby-based virus scanner available on the market for a good
reason: it is a heavy task. Therefore, this gem may not work as automagically
as you are used to with many other gems.

You will need to setup a virus scanner on your machine. If you have done that
before, configuration should be rather simple. Instructions are provided for
the open source ClamAV scanner in the
[`ratonvirus-clamby`](https://github.com/mainio/ratonvirus-clamby)
documentation.

This gem ships with an example
[EICAR file](https://en.wikipedia.org/wiki/EICAR_test_file) scanner to test out
the configuration process. This scanner allows you to test the functionality of
this gem with no external requirements but it should not be used in production
environments.

## Installation

Add this line to your application's Gemfile:

```ruby
gem "ratonvirus"
```

And then execute:

```bash
$ bundle
```

Add this initializer to your application's `config/initializers/ratonvirus.rb`:

```ruby
# config/initializers/ratonvirus.rb
Ratonvirus.configure do |config|
  config.scanner = :eicar
  config.storage = :active_storage
end
```

After installation, test that the gem is loaded properly in your it is ready to
do a sample validation:

```bash
$ bundle exec rails ratonvirus:test
```

This command should show the following message when correctly installed:

```
Ratonvirus correctly configured.
```

**NOTE:**

By default Ratonvirus is set to remove all infected files that it detects after
scanning them. If you want to remove this functionality, please refer to the
[Scanner addons](docs/index.md#scanner-addons) section of the developer
documentation.

## Usage

### Applying the antivirus validator to your models

In order to apply the antivirus validator, you need to have your file uploads
handled by a storage backend such as Active Storage. Examples are provided below
for the most common options.

#### Example with Active Storage

Your model should look similar to this:

```ruby
class YourModel < ApplicationRecord
  has_one_attached :file
  validates :file, antivirus: true # Add this for antivirus validation
end
```

#### Example with CarrierWave

Your model should look similar to this:

```ruby
class YourModel < ApplicationRecord
  mount_uploader :file, YourUploader
  validates :file, antivirus: true # Add this for antivirus validation
end
```

Please note the extra configuration you need for CarrierWave from the
configuration examples.

### Manually checking for viruses

For the manual scans to work you need to configure the correct storage backend
first that accepts these resources:

```ruby
# config/initializers/ratonvirus.rb

# When scanning files or file paths only
Ratonvirus.configure do |config|
  config.storage = :filepath
end

# When scanning files, file paths or active storage resources
Ratonvirus.configure do |config|
  config.storage = :multi, {storages: [:filepath, :active_storage]}
end
```

In case you want to manually scan for viruses, you can use any of the following
examples:

```ruby
# It is a good idea to check first that the scanner is available.
if Ratonvirus.scanner.available?
  # Scanning a file path
  path = "/path/to/file.pdf"
  if Ratonvirus.scanner.virus?(path)
    puts "There is a virus at #{path}"
  end

  # Scanning a File object
  file = File.new(path)
  if Ratonvirus.scanner.virus?(file)
    puts "There is a virus at #{file.path}"
  end
end
```

### Sample configurations

Here are few sample configurations to speed up the configuration process.

#### Active Storage and ClamAV

Gemfile:

```ruby
gem "ratonvirus"
gem "ratonvirus-clamby"
```

Initializer:

```ruby
# config/initializers/ratonvirus.rb
Ratonvirus.configure do |config|
  config.scanner = :clamby
  config.storage = :active_storage
end
```

Model:

```ruby
class YourModel < ApplicationRecord
  has_one_attached :file
  validates :file, antivirus: true
end
```

For installing ClamAV, refer to
[`ratonvirus-clamby`](https://github.com/mainio/ratonvirus-clamby)

#### CarrierWave and ClamAV

Gemfile:

```ruby
gem "ratonvirus"
gem "ratonvirus-clamby"
```

Initializer:

```ruby
# config/initializers/ratonvirus.rb
Ratonvirus.configure do |config|
  config.scanner = :clamby
  config.storage = :carrierwave
end
```

Model:

```ruby
class YourModel < ApplicationRecord
  mount_uploader :file, YourUploader
  validates :file, antivirus: true
end
```

For installing ClamAV, refer to
[`ratonvirus-clamby`](https://github.com/mainio/ratonvirus-clamby)

## Further configuration and development

For further information about the configurations and how to create custom
scanners, please refer to the [documentation](docs/index.md).

## License

MIT, see [LICENSE](LICENSE).
