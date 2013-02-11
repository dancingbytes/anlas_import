require 'rails/railtie'

module AnlasImport

  class Railtie < ::Rails::Railtie #:nodoc:

    config.after_initialize do

      Imp( ::AnlasImport::proc_name, ::AnlasImport::daemon_log ) do

        loop do

          ::AnlasImport::Manager.run
          sleep ::AnlasImport::wait

        end # loop

      end # Imp

      if !defined?(::IRB) && !defined?(::Rake) && ::Rails.env.to_s == "production"
        Imp(::AnlasImport::proc_name).start
      end # if

    end # initializer

  end # Railtie

end # AnlasImport
