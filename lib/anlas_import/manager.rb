# encoding: UTF-8
module AnlasImport

  # Предварительная обработка выгрузки (распаковка архивов).
  # Запуск обработчика. Отправка отчетов.
  class Manager

    def self.run(file_path)
      new.run(file_path)
    end # self.run

    def initialize
      @has_files = false
    end # new

    def run(file_path)

      # Распаковываем zip архив, если такой имеется.
      # Подготавливаем список файлов к обработке
      files = if is_zip?(file_path)
        extract_zip_file(file_path)
      else
        [file_path]
      end

      files.each { |xml_file|
        ::AnlasImport::Worker.parse(xml_file)
      }

      ::AnlasImport.close_logger

      yield if @has_files && block_given?

    end # run

    private

    def log(msg)
      ::AnlasImport.log(msg)
    end # log

    def import_dir
      ::AnlasImport::import_dir
    end # import_dir

    def extract_zip_file(file_name)

      files = []
      begin

        ::Zip::File.open(file_name) { |zip_file|

          zip_file.each { |f|

            # Создаем дополнительную вложенность т.к. 1С 8 выгружает всегда одни и теже
            # навания файлов, и если таких выгрузок будет много, то при распковке файлы
            # будут перезатираться

            f_path = ::File.join(
              import_dir,
              f.file? ? "#{rand}-#{::Time.now.to_f}-#{f.name}" : f.name
            )

            files << f_path

            ::FileUtils.rm_rf(f_path) if ::File.exist?(f_path)
            ::FileUtils.mkdir_p(::File.dirname(f_path))

            zip_file.extract(f, f_path)

          } # each

        } # open

        ::FileUtils.rm_rf(file_name)

      rescue => e
        log("[extract_zip_file] #{e.backtrace.join('\n')}")
      end

      files

    end # extract_zip_file

    def is_zip?(file_name)

      begin
        ::Zip::File.open(file_name) { |zip_file| }
        true
      rescue
        false
      end

    end # is_zip?

  end # Manager

end # AnlasImport
