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

      @errors         = []
      @inserted_items = []
      @updaed_items   = []

      check_import_dir
      read_db_config

    end # new

    def run

      before
      processing if @errors.empty?
      after

      yield(
        @inserted_items.flatten.uniq, 
        @updaed_items.flatten.uniq
      ) if block_given? && @has_files

    end # run

    def log(msg = "")

      create_logger unless @logger
      @logger.error(msg) if @logger
      msg

    end # log

    private

    def before

      open_db_connection
      @has_files = false
      extract_zip_files

    end # before_start

    def after

      unless @errors.empty?
        msg = self.log(@errors.flatten.join("\n\r"))
        ::AnlasImport::Mailer.new.send_message("Выгрузка данных из 1С. Ошибки.", msg)
      end

      close_logger
      close_db_connect
      
    end # after

    def processing

      files = ::Dir.glob( ::File.join(@config[:dir], "**", "*.xml") )
      return unless files && files.size > 0

      @has_files = true
      
      #threads = []
      start = ::Time.now.to_i
      @errors << "\n\n[#{Time.now.strftime('%H:%M:%S %d-%m-%Y')}] Обработка файлов импорта ===================\n"

      files.each do |xml_file|
        
        #threads << Thread.new {
          
          worker = ::AnlasImport::Worker.new(xml_file, @conn).parse

          @errors         << worker.errors
          @inserted_items << worker.inserted
          @updaed_items   << worker.updated

        #}
        
      end # each

      #threads.join

      @errors << "Добавлено товаров: #{@inserted_items.length}\n"
      @errors << "Обновлено товаров: #{@inserted_items.length}\n"
      @errors << "Затрачено времени: #{Time.now.to_i - start} секунд.\n"
      @errors << "===========================================================================\n\n"

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
        @conn = ::Mongoid.database
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

      return unless @conn
      @conn.logout rescue nil
      @conn = nil

    end # close_db_connect

  end # Manager

end # AnlasImport