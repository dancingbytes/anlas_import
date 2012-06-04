# encoding: utf-8
module AnlasImport

  TABLE_MATCHES = {

    # (postfix) => (prefix)
    'a' => '',   # Аксессуары
    'g' => 'a',  # Аккумуляторы
    'h' => 'h',  # Химия
    'e' => 'e',  # Электроника
    't' => 't'   # Инструменты

  }

  class Base

    def self.backup_dir
      "/home/webmaster/backups/imports/"
    end # backup_dir

    def self.run
      puts "This method must be redefined"
    end # self.run

    def self.can_start?

      return false if defined?(::IRB)
      return false if defined?(::Rake)
      return false unless defined?(::Rails)
      return false if ::Rails.env.to_s != "production"
      true

    end # self.can_start?

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