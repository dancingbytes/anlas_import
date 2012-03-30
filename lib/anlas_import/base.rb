# encoding: utf-8
module AnlasImport
  
  class Base

    class << self

      def run

        ::Imp.run(::AnlasImport::PROC_NAME, ::File.join(::Rails.root, "log", "import_xml.log")) do
          
          # TODO Предотвращает падение логгера, но остановка демона все равно не корректна
          log_path = ::Rails.logger.instance_variable_get(:@log).path
          ::Rails.logger = ::ActiveSupport::BufferedLogger.new(log_path)
          
          puts "#{::Time.now} #{::AnlasImport::PROC_NAME} start"
          
          import_dir = ::File.join("#{::Rails.root}", "tmp", "xml")
          log_dir = ::File.join("#{::Rails.root}", "log")
          db_conf_file = ::File.join("#{::Rails.root}", "config", "mongoid.yml")

          loop do
            
            ::AnlasImport::Manager.new(import_dir, log_dir, db_conf_file).run do |inserted, updated|

              updated.uniq.each do |id|
                Item.where(:_id => id).first.try(&:update_sphinx)
              end

            end

            sleep 20 * 60 # 20 minutes

          end # loop

        end # Imp.run

      end # self.run

    end # class << self

  end # Base
  
end # ImportXml
