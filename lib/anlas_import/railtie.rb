# encoding: utf-8
require 'rails/railtie'

module AnlasImport

  class Railtie < ::Rails::Railtie #:nodoc:
    
    initializer 'anlas_import' do |app|
      
      if ::Rails.env.to_s == "production" && ::Rails.groups.exclude?("assets")
        ::AnlasImport::Base.run
      end

    end # initializer

  end # Railtie

end # AnlasImport