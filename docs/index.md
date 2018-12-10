# Ratonvirus - Developer documentation

This documentation provides information about how to plug Ratonvirus to
different scanning backends

## Concepts

This library acts as the glue between your Rails application and an arbitrary
virus scanner and file storage engine.

### Scanners

Binding the scanning to the actual scanner implementation is done through
Ratonvirus scanners. The actual scanning can be handled e.g. with `system`
calls or calls to external scanning APIs.

### Storages

Binding the scannable resources to different file storage engines (such as
Active Storage or CarrierWave) is done through Ratonvirus storages. These
storages provide functionality for the file resources such as determining their
file paths on the local file system or removing the resources.

### Scanner addons

You are able to extend the scanning functionality through scanner addons. These
can be used for example to add additional hooks before and after the scanning
process in case you want the scanner to do something else than scan the file and
report whether it was infected.

An example implementation of an addon module can be found in the gem's
`lib/ratonvirus/scanner/addon/remove_infected.rb`. This example is applied to
the configured scanner by default.

## About scanners

### Scanner: eicar

The `eicar` scanner backend checks the given files against the
[EICAR test file](https://en.wikipedia.org/wiki/EICAR_test_file) string.

This scanner should not be used in production applications as it will not detect
any actual viruses. This should only be used for development and testing
purposes.

To configure this scanner, use the following code in the Ratonvirus initializer:

```ruby
# config/initializers/ratonvirus.rb
Ratonvirus.configure do |config|
  config.scanner = :eicar
end
```

### Scanner: clamby

Clamby provides an integration library for the ClamAV virus scanner. Using this
scanner type requires you to have the ClamAV virus scanner executables installed
on your machine.

For further installation instructions, please refer to `ratonvirus-clamby`
documentation.

### Implement your own scanner

Take a look at [Implementing custom scanners](#implementing-custom-scanners).

## About storages

### Storage: filepath

The filepath storage works with:

- File path strings (validating files directly)
- File objects (validating files directly)

To configure this storage, use the following code in the Ratonvirus initializer:

```ruby
# config/initializers/ratonvirus.rb
Ratonvirus.configure do |config|
  config.storage = :filepath
end
```

Scanning resources:

```ruby
if Ratonvirus.scanner.virus?('/path/to/file.pdf')
  puts "The file contains a virus."
end
if Ratonvirus.scanner.virus?(File.new('/path/to/file.pdf'))
  puts "The file contains a virus."
end
```

### Storage: active_storage

The `active_storage` storage backend works with Active Storage resources
(validator attached to Active Storage backed models).

To configure this storage, use the following code in the Ratonvirus initializer:

```ruby
# config/initializers/ratonvirus.rb
Ratonvirus.configure do |config|
  config.storage = :active_storage
end
```

Scanning resources:

```ruby
if Ratonvirus.scanner.virus?(your_model.file)
  puts "The file contains a virus."
end
```

### Storage: multi

The `multi` storage backend works with multiple storage backends if you want to
use the same storage for the validators and file paths for instance.

To configure this storage, use the following code in the Ratonvirus initializer:

```ruby
# config/initializers/ratonvirus.rb
Ratonvirus.configure do |config|
  config.storage = :multi, {storages: :filepath, :active_storage}
end
```

Scanning resources:

```ruby
if Ratonvirus.scanner.virus?('/path/to/file.pdf')
  puts "The file contains a virus."
end
if Ratonvirus.scanner.virus?(File.new('/path/to/file.pdf'))
  puts "The file contains a virus."
end
if Ratonvirus.scanner.virus?(your_model.file)
  puts "The file contains a virus."
end
```

### Implement your own storage

Take a look at [Implementing custom storages](#implementing-custom-storages).

## About scanner addons

### Scanner addon: remove_infected

**APPLIED BY DEFAULT**

This addon removes the scanned files from the file system in case they were
detected to contain a virus.

### Configuring scanner addons

After creating the addon module, you can use the following configuration code
to add it to any new scanner instances:

```ruby
Ratonvirus.configure do |config|
  # This would add the `Ratonvirus::Scanner::Addon::CustomAddon` to any new
  # scanner instances. Existing instances are not affected
  config.add_addon :custom_addon
end
```

You can also remove any existing addons from being added to any new scanner
instances with  the following configuration:

```ruby
Ratonvirus.configure do |config|
  # This would remove the `Ratonvirus::Scanner::Addon::CustomAddon` from being
  # applied to any new scanner instances. Existing instances are not affected.
  config.remove_addon :custom_addon
end
```

Please note that in case the scanner has already been initialized prior to
these configuration blocks, adding or removing the addons will not do
anything.

The available addons shipped with this gem are described below. Those that are
marked as **default** are applied by default without explicitly configuring
them.

## Extending the functionality

### Implementing custom scanners

To implement a custom scanner, you can take a look at the `eicar` scanner at
`lib/ratonvirus/scanner/eicar.rb`. A basic scanner implementation would look
something like this:

```ruby
module Ratonvirus
  module Scanner
    class Custom < Base
      class << self
        def executable?
          AntivirusChecker.installed?
        end
      end

      protected
        def run_scan(path)
          if File.file?(path)
            if AntivirusChecker.virus?(path)
              errors << :antivirus_virus_detected
            end
          else
            errors << :antivirus_file_not_found
          end
        rescue
          # There was some exception thrown from the AntivirusChecker.
          errors << :antivirus_client_error
        end
    end
  end
end
```

The default errors for which error messages are provided by this gem are:

- `antivirus_virus_detected` - Virus was detected.
- `antivirus_client_error` - There was a problem running the scanner.
- `antivirus_file_not_found` - The scanner did not find the file.

The checker implementation would look something like this:

```ruby
class AntivirusChecker
  # Define this method to check that the scanner available on your machine.
  # For API-based scanners, this should check that the connection to the API
  # works correctly and accepts new requests.
  def self.installed?
    true
  end

  # Define this method to actually scan the virus using the scanner.
  def self.virus?(filepath)
    raise "TODO: do your scan here!"
  end
end
```

Configure it to be used:

```ruby
Ratonvirus.configure do |config|
  config.scanner = :custom
end
```

### Implementing custom scanner addons

Defining a custom scanner addon consists of two steps:

1. Create a module in the `Ratonvirus::Scanner::Addon` namespace
1. Implement the `self.extended` method in that module. The scanner is passed as
   an argument to this method to which you can apply e.g. before and after
   hooks.

The addon implementation would look something like this:

```ruby
module Ratonvirus
  module Scanner
    module Addon
      module CustomAddon
        def self.extended(scanner)
          # Apply the hooks for the scanner
          scanner.before_scan :run_this_before_scan
          scanner.after_scan :run_this_after_scan
        end

        private
          def run_this_before_scan(processable)
            puts "This is run BEFORE scan."
            puts "An instance of Ratonvirus::Processable:"
            puts processable.inspect
          end

          def run_this_after_scan(processable)
            puts "This is run AFTER scan."
            puts "An instance of Ratonvirus::Processable:"
            puts processable.inspect
          end
      end
    end
  end
end
```

Then, configure it to be used:

```ruby
Ratonvirus.configure do |config|
  config.add_addon :custom
end
```

Next time any scanning is run, the example hooks are called before and after
the scanning process. In the addon, you have access to all methods inside the
scanner as it is run in the same context.

### Implementing custom storages

To implement a custom storage, you can take a look at the implemented storages
in the `lib/ratonvirus/storage` folder. A basic simple storage implementation
would look something like this:

```ruby
module Ratonvirus
  module Storage
    class Custom < Base
      # The changed? method is used by the validator to check whether the scan
      # should be run against this resource. Usually it should not be necessary
      # to scan the resources that have not changed.
      #
      # The `record` and `attribute` are the same ones that are passed to the
      # validator by Rails.
      def changed?(record, attribute)
        record.send_public(:"#{attribute}_changed?")
      end

      # The accept? defines what type of resources this storage expects.
      def accept?(resource)
        resource.is_a?(MyExpectedTypeOfResource)
      end

      # The asset_path method should define a local file path on the running
      # machine where the file can be found for the scanner to process it. E.g.
      # remote storages may not have the file stored on the local disk in which
      # a local copy needs to be defined prior to the scanning process.
      #
      # Please note that you need to yield the resource's path from this method.
      # Yielding a clean way to allow the remote storages to download the local
      # copy although it may not make that much sense for storages that already
      # have the files locally stored
      def asset_path(resource)
        return unless block_given?
        return if resource.nil?

        # Note that you need to yield the asset's path.
        yield resource.path
      end

      # The asset_remove method should remove the resource. This does not mean
      # the local copy created by asset_path (it should already be removed after
      # scanning finishes). This is needed e.g. for remote storages to remove
      # the file and all references to it altogether.
      def asset_remove(resource)
        resource.remove!
      end
    end
  end
end
```

Configure it to be used:

```ruby
Ratonvirus.configure do |config|
  config.storage = :custom
end
```
