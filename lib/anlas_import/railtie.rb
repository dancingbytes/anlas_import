# encoding: utf-8
require 'rails/railtie'

module AnlasImport

  class Railtie < ::Rails::Railtie #:nodoc:

    initializer 'anlas_import' do |app|

      ::AnlasImport::Base.run if ::AnlasImport.can_start?

    end # initializer

  end # Railtie

end # AnlasImport