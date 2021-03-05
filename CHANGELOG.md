# v0.3.0

Changed:

- Minimum Ruby version is now set to 2.5

Fixed:

- Issue related with scanning files with CarrierWave storage engine using remote storage engines such as Fog. Related
  to [#9](https://github.com/mainio/ratonvirus/pull/9)

# v0.2.0

Support for Rails 6

The ActiveStorage storage engine has been updated and partly rewritten due to changes in its API. The new API introduces
a changes concept in the library which this update takes in to account. In the new API, the blobs will not get uploaded
to the storage service before the validations have been successful, which led to rethinking how this storage engine
works in Ratonvirus.


# v0.1.1

Fixed:

- Rescue file not found exception for blob.download [#2](https://github.com/mainio/ratonvirus/pull/2)

# v0.1.0

Initial public release.
