# encoding: utf-8
require 'logger'
require 'zip'
require 'fileutils'
require 'yaml'
require 'nokogiri'
require 'base64'

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
    @import_dir ||= ::File.join(::Rails.root, "tmp", "exchange_1c")

    ::FileUtils.mkdir_p(@import_dir) unless ::FileTest.directory?(@import_dir)

    @import_dir

  end # import_dir

  def backup_dir(v = nil)

    @backup_dir = v unless v.blank?
    @backup_dir

  end # backup_dir

  def log_dir(v = nil)

    @log_dir = v unless v.blank?
    @log_dir ||= ::File.join(::Rails.root, "log")

    ::FileUtils.mkdir_p(@log_dir) unless ::FileTest.directory?(@log_dir)

    @log_dir

  end # log_dir

  def run_async(file_path)

    ::AnlasImportWorker.perform_async(file_path)
    self

  end # run_async

  def run_async_all

    files = ::Dir.glob( ::File.join(import_dir, '**', '{*.xml,*.zip}') )

    # Сортируем по дате последнего доступа по-возрастанию
    files.sort { |a, b|
      ::File.new(a).mtime <=> ::File.new(b).atime
    }.each do |file_path|

      run_async(file_path)

    end # each

    self

  end # run_async_all

  def update(v = nil)

    @update_callback = v if v.is_a?(::Proc)
    @update_callback

  end # update

  def backup_file_to_dir(file)

    return false if file.nil?

    begin

      unless ::AnlasImport::backup_dir.nil?

        dir = Time.now.utc.strftime(::AnlasImport::backup_dir).gsub(/%[a-z]/, '_')

        ::FileUtils.mkdir_p(dir, mode: 0755) unless ::FileTest.directory?(dir)
        return false unless ::FileTest.directory?(dir)

        ::FileUtils.mv(file, dir)

      end # unless

    rescue SystemCallError
      log "Не могу переместить файл `#{::File.basename(file)}` в `#{dir}`"
    rescue => ex
      log ex.inspect
    ensure
      ::FileUtils.rm_rf(file)
    end

  end # backup_file_to_dir

  def log(msg = "")

    (@dump_log ||= "") << "#{msg}\n"

    create_logger       unless @logger
    @logger.error(msg)  if @logger

    msg

  end # log

  def close_logger

    return unless @logger
    @logger.close
    @logger = nil

  end # close_logger

  def dump_log
    @dump_log || ""
  end # dump_log

  def clear_log
    @dump_log = nil
  end # clear_log

  private

  def create_logger

    return if @logger
    return unless ::AnlasImport::log_dir && ::FileTest.directory?(::AnlasImport::log_dir)

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
require 'anlas_import/util'

require 'anlas_import/xml_parser'
require 'anlas_import/worker'
require 'anlas_import/manager'

if defined?(::Rails)
  require 'anlas_import/engine'
  require 'anlas_import/railtie'
end
