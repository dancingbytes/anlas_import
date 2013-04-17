# encoding: UTF-8
module AnlasImport

  # Предварительная обработка выгрузки (распаковка архивов).
  # Запуск обработчика. Отправка отчетов.
  class Manager

    def self.run
      new.run
    end # self.run

    def initialize
    end # new

    def run

      @has_files = false

      extract_zip_files
      processing
      close_logger

      yield if @has_files && block_given?

    end # run

    def log(msg = "")

      create_logger unless @logger
      @logger.error(msg)
      msg

    end # log

    private

    def processing

      unless ::AnlasImport::import_dir && ::FileTest.directory?(::AnlasImport::import_dir)
        log "Директория #{::AnlasImport::import_dir} не существует!"
        return
      end

      files = ::Dir.glob( ::File.join(::AnlasImport::import_dir, "**", "*.xml") )
      return unless files && files.size > 0

      @has_files = true
      # Сортируем по дате последнего доступа по-возрастанию
      files.sort{ |a, b| ::File.new(a).mtime <=> ::File.new(b).atime }.each do |xml_file|
        ::AnlasImport::Worker.new(xml_file, self).parse
      end # each

      self

    end # processing

    def extract_zip_files

      # Ищем и распаковываем все zip-архивы, после - удаляем
      files = ::Dir.glob( ::File.join(::AnlasImport::import_dir, "**", "*.zip") )
      return unless files && files.size > 0

      i = 0
      files.each do |zip|

        i+= 1
        begin

          ::Zip::ZipFile.open(zip) { |zip_file|

            zip_file.each { |f|

              # Создаем дополнительную вложенность т.к. 1С 8 выгружает всегда одни и теже
              # навания файлов, и если таких выгрузок будет много, то при распковке файлы
              # будут перезатираться
              f_path = ::File.join(::AnlasImport::import_dir, "#{i}", f.name)
              ::FileUtils.rm_rf f_path if ::File.exist?(f_path)
              ::FileUtils.mkdir_p(::File.dirname(f_path))
              zip_file.extract(f, f_path)

            } # each

          } # open

          ::FileUtils.rm_rf(zip)

        rescue
        end

      end # Dir.glob

    end # extract_zip_files

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

    def close_logger

      return unless @logger
      @logger.close
      @logger = nil

    end # close_logger

  end # Manager

end # AnlasImport
