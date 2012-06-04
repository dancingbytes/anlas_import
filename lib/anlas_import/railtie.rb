require 'rails/railtie'

module AnlasImport

  class Railtie < ::Rails::Railtie #:nodoc:

    config.after_initialize do

      ::AnlasImport::Base.run

    end # initializer

  end # Railtie

end # AnlasImport