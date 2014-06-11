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
    'номенклатура аксессуаров'  => 1,

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

  def run
    ::AnlasImport::Manager.run
  end # run

  def backup_file_to_dir(file)

    return false if file.nil?
    return false if ::AnlasImport::backup_dir.nil?

    begin

      dir = Time.now.utc.strftime(::AnlasImport::backup_dir).gsub(/%[a-z]/, '_')

      ::FileUtils.mkdir_p(dir, mode: 0755) unless ::FileTest.directory?(dir)
      return false unless ::FileTest.directory?(dir)

      ::FileUtils.mv(file, dir)

    rescue SystemCallError
      log "Не могу переместить файл `#{::File.basename(file)}` в `#{dir}`"
    rescue => ex
      log ex.inspect
    ensure
      ::FileUtils.rm_rf(file)
    end

  end # backup_file_to_dir

  def log(msg = "")

    create_logger unless @logger
    @logger.error(msg)
    msg

  end # log

  def close_logger

    return unless @logger
    @logger.close
    @logger = nil

  end # close_logger

  private

  def create_logger

    return unless ::AnlasImport::log_dir && ::FileTest.directory?(::AnlasImport::log_dir)
    return if @logger

    ::FileUtils.mkdir_p(::AnlasImport::log_dir) unless ::FileTest.directory?(::AnlasImport::log_dir)
    log_file = ::File.open(
      ::File.join(::AnlasImport::log_dir, "import.log"),
      ::File::WRONLY | ::File::APPEND | ::File::CREAT
    )
    log_file.sync = true
    @logger = ::Logger.new(log_file, 'weekly')
    @logger

  end # create_logger

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

at_exit {
  ::AnlasImport.close_logger
}
