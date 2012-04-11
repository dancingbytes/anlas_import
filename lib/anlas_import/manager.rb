# encoding: UTF-8
module AnlasImport

  # Предварительная обработка выгрузки (распаковка архивов). Проверка
  # соедиения с базой данных. Запуск обработчика. Отправка отчетов.
  class Manager
    
    def initialize(import_dir, log_dir, db_conf_file)

      @config = {
        :dir => import_dir,
        :log => log_dir,
        :db_conf  => db_conf_file
      }

      reset
      check_import_dir
      read_db_config

    end # new

    def run

      before
      
      if @errors.empty?

        start = ::Time.now.to_i
        @errors << "[#{Time.now.strftime('%H:%M:%S %d-%m-%Y')}] Обработка файлов импорта ============================"
        
        processing

        @errors << "Добавлено товаров: #{@inserted_items.length}"
        @errors << "Обновлено товаров: #{@updaed_items.length}"
        @errors << "Затрачено времени: #{ '%0.3f' % (Time.now.to_f - start) } секунд."
        @errors << "===========================================================================\n"

      end # if

      after
      yield(@inserted_items, @updaed_items ) if block_given? && @has_files
      reset

    end # run

    def log(msg = "")

      create_logger unless @logger
      @logger.error(msg) if @logger
      msg

    end # log

    private

    def reset

      @errors         = []
      @inserted_items = []
      @updaed_items   = []
      @has_files      = false

    end # reset

    def before

      open_db_connection
      extract_zip_files

    end # before_start

    def after

      unless @errors.empty?
        msg = self.log(@errors.flatten.join("\n"))
        ::AnlasImport::Mailer.new.send_message("Выгрузка данных из 1С. Ошибки.", msg)
      end

      close_logger
      close_db_connect

    end # after

    def processing

      files = ::Dir.glob( ::File.join(@config[:dir], "**", "*.xml") )
      return unless files && files.size > 0

      @has_files = true      

      files.each do |xml_file|
        
        worker = ::AnlasImport::Worker.new(xml_file, @conn).parse

        @errors << worker.errors
        @inserted_items = @inserted_items.concat(worker.inserted)
        @updaed_items   = @updaed_items.concat(worker.updated)
        
      end # each

      @inserted_items.uniq!
      @updaed_items.uniq!

      self

    end # processing

    def check_import_dir

      unless @config[:dir] && ::FileTest.directory?(@config[:dir])
        @errors << "Директория #{@config[:dir]} не существует!"
      end

    end # check_import_dir

    def read_db_config

      begin
        @config[:db_conf] = ::YAML::load_file(@config[:db_conf])["production"]
      rescue => e
        @errors << "#{e}"
      end

      @errors << "Не найден раздел :production в файле конфигурации database.yml " if @config[:db_conf].nil?

    end # read_db_config

    def open_db_connection

      begin
        ::Mongoid.database.collection("admin").find_one
        @conn ||= ::Mongoid.database
      rescue => e
        @errors << "Нет соединения с базой данных."
      end # begin
      
    end # open_db_connection

    def extract_zip_files

      # Ищем и распаковываем все zip-архивы, после - удаляем
      files = ::Dir.glob( ::File.join(@config[:dir], "**", "*.zip") )
      return unless files && files.size > 0

      files.each do |zip|

        ::Zip::ZipFile.open(zip) { |zip_file|

          zip_file.each { |f|

            f_path = ::File.join(@config[:dir], f.name)
            ::FileUtils.rm_rf f_path if ::File.exist?(f_path)
            ::FileUtils.mkdir_p(::File.dirname(f_path))
            zip_file.extract(f, f_path)
            
          } # each

        } # open

        ::FileUtils.rm_rf(zip)

      end # Dir.glob

    end # extract_zip_files

    def create_logger

      return unless @config[:log] && ::FileTest.directory?(@config[:log])
      return if @logger

      ::FileUtils.mkdir_p(@config[:log]) unless ::FileTest.directory?(@config[:log])
      @logger = ::Logger.new(
        ::File.open(
          ::File.join(@config[:log], "import.log"), ::File::WRONLY | ::File::APPEND | ::File::CREAT
        )
      )

    end # create_logger

    def close_logger

      return unless @logger
      @logger.close
      @logger = nil

    end # close_logger

    def close_db_connect
      # no need for mongoid
    end # close_db_connect

  end # Manager

end # AnlasImport