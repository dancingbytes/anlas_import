require 'rails/railtie'

module AnlasImport

  class Railtie < ::Rails::Railtie #:nodoc:

    config.after_initialize do

      Imp( ::AnlasImport::proc_name, ::AnlasImport::daemon_log ) do

        loop do

          ::AnlasImport::run
          ::GC.start
          sleep ::AnlasImport::wait

        end # loop

      end # Imp

    end # initializer

  end # Railtie

end # AnlasImport
