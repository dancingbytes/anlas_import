# encoding: utf-8
module AnlasImport

  extend self

  def can_start?

    return false if defined?(::IRB)
    return false if defined?(::Rake)
    return false unless defined?(::Rails)
    return false if ::Rails.env.to_s != "production"
    true

  end # can_start?

  class Base

    def self.run
      puts "This method must be redefined"
    end # self.run

  end # Base

end # AnlasImport

require 'logger'
require 'zip/zip'
require 'fileutils'
require 'yaml'
require 'nokogiri'

require 'anlas_import/version'

require 'anlas_import/ext'
require 'anlas_import/mailer'

require 'anlas_import/base'

require 'anlas_import/xml_parser'
require 'anlas_import/worker'
require 'anlas_import/manager'

require 'anlas_import/railtie' if defined?(::Rails)