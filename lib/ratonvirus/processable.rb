# frozen_string_literal: true

module Ratonvirus
  class Processable
    def initialize(storage, asset)
      @storage = storage
      @asset = asset
    end

    def path(&)
      return unless block_given?

      @storage.asset_path(@asset, &)
    end

    def remove
      @storage.asset_remove(@asset)
    end
  end
end
