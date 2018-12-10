class Article < ApplicationRecord
  # Active Storage
  has_one_attached :activestorage_file
  validates :activestorage_file, antivirus: true

  has_many_attached :activestorage_files
  validates :activestorage_files, antivirus: true

  # CarrierWave
  mount_uploader :carrierwave_file, AttachmentUploader
  validates :carrierwave_file, antivirus: true

  mount_uploaders :carrierwave_files, AttachmentUploader
  validates :carrierwave_files, antivirus: true
end
