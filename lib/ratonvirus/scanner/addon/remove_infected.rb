# frozen_string_literal: true

module Ratonvirus
  module Scanner
    module Addon
      module RemoveInfected
        def self.extended(validator)
          validator.after_scan :remove_infected_file
        end

        private

        def remove_infected_file(processable)
          return unless errors.include?(:antivirus_virus_detected)

          processable.remove
        end
      end
    end
  end
end
