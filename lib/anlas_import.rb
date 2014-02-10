# encoding: utf-8
require 'logger'
require 'zip/zip'
require 'fileutils'
require 'yaml'
require 'nokogiri'

module AnlasImport

  extend self

  DEPS = {

    'аксессуары'  => 1,

    'номенклатура автохимии' => 3,
    'химия'       => 3,
    'автохимия'   => 3,

    'инструменты' => 4,
    'инструмент'  => 4,
    'номенклатура инструментов' => 4,

    'ваз'         => 2,
    'авто_ваз'    => 2,
    'номенклатура ваз'  => 2,

    'газ'         => 6,
    'номенклатура газ'  => 6,

    'иномарки'    => 5,
    'номенклатура иномарок' => 5

  }.freeze

  def supplier_code(name)
    ::AnlasImport::DEPS[name.downcase]
  end # supplier_code

  def proc_name(v = nil)

    @proc_name = v unless v.blank?
    @proc_name

  end # proc_name

  def login(v = nil)

    @login = v unless v.blank?
    @login

  end # login

  def password(v = nil)

    @pass = v unless v.blank?
    @pass

  end # password

  alias :pass :password

  def import_dir(v = nil)

    @import_dir = v unless v.blank?
    @import_dir

  end # import_dir

  def backup_dir(v = nil)

    @backup_dir = v unless v.blank?
    @backup_dir

  end # backup_dir

  def daemon_log(v = nil)

    @daemon_log = v unless v.blank?
    @daemon_log

  end # daemon_log

  def log_dir(v = nil)

    @log_dir = v unless v.blank?
    @log_dir || ::File.join(::Rails.root, "log")

  end # log_dir

  def wait(v = nil)

    @wait = v.abs if v.is_a?(::Fixnum)
    @wait || 5 * 60

  end # wait

end # AnlasImport

require 'anlas_import/version'

require 'anlas_import/ext'
require 'anlas_import/mailer'

require 'anlas_import/xml_parser'
require 'anlas_import/worker'
require 'anlas_import/manager'

if defined?(::Rails)
  require 'anlas_import/engine'
  require 'anlas_import/railtie'
end

