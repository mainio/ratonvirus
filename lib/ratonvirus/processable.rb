module Ratonvirus
  class Processable
    def initialize(storage, asset)
      @storage = storage
      @asset = asset
    end

    def path(&block)
      return unless block_given?
      @storage.asset_path(@asset, &block)
    end

    def remove
      @storage.asset_remove(@asset)
    end
  end
end
