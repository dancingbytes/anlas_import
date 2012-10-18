# encoding: UTF-8
module AnlasImport

  # Предварительная обработка выгрузки (распаковка архивов).
  # Запуск обработчика. Отправка отчетов.
  class Manager

    def initialize(import_dir, log_dir)

      @config = {
        :dir => import_dir,
        :log => log_dir
      }

      reset
      check_import_dir

    end # new

    def run

      before

      if @errors.empty?

        start = ::Time.now.to_i
        processing

        if (@inserted_items.length + @updaed_items.length > 0)

          @errors << "[#{Time.now.strftime('%H:%M:%S %d-%m-%Y')}] Обработка файлов импорта ============================"
          @errors << "Добавлено товаров: #{@inserted_items.length}"
          @errors << "Обновлено товаров: #{@updaed_items.length}"
          @errors << "Затрачено времени: #{ '%0.3f' % (Time.now.to_f - start) } секунд."
          @errors << "===========================================================================\n"

        end # if

      end # if

      after

      yield(@inserted_items, @updaed_items) if @has_files && block_given?
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
      extract_zip_files
    end # before_start

    def after

      self.log(@errors.flatten.join("\n")) unless @errors.empty?
      close_logger

    end # after

    def processing

      files = ::Dir.glob( ::File.join(@config[:dir], "**", "*.xml") )
      return unless files && files.size > 0

      @has_files = true

      files.each do |xml_file|

        worker = ::AnlasImport::Worker.new(xml_file).parse

        @errors << worker.errors
        @inserted_items = @inserted_items.concat(worker.inserted)
        @updaed_items   = @updaed_items.concat(worker.updated)
        @supplier_code  = worker.supplier

        # Обнуляем количество для товаров не обновлявшихся 5 дней
        Item.where(:supplier_code => @supplier_code, :imported_at.lt => Time.now.utc - 5.days).each do |item|
          item.available = 0
          item.save(validate: false)
        end


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

    def extract_zip_files

      # Ищем и распаковываем все zip-архивы, после - удаляем
      files = ::Dir.glob( ::File.join(@config[:dir], "**", "*.zip") )
      return unless files && files.size > 0

      files.each do |zip|

        begin

          ::Zip::ZipFile.open(zip) { |zip_file|

            zip_file.each { |f|

              f_path = ::File.join(@config[:dir], f.name)
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

  end # Manager

end # AnlasImport
