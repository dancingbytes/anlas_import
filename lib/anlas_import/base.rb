# encoding: utf-8
module AnlasImport
  
  class Base

    class << self

      def run

        ::Imp.run(::AnlasImport::PROC_NAME, ::File.join(::Rails.root, "log", "import_xml.log")) do
          
          puts "#{::Time.now} #{::AnlasImport::PROC_NAME} start"
          
          import_dir    = "/home/import"
          log_dir       = ::File.join("#{::Rails.root}", "log")
          db_conf_file  = ::File.join("#{::Rails.root}", "config", "mongoid.yml")

          loop do
            
            ::AnlasImport::Manager.new(import_dir, log_dir, db_conf_file).run do |inserted, updated|

              updated.each do |id|
                ::Item.where(:_id => id).first.try(&:update_sphinx)
              end
              
            end # run

            sleep 5 * 60 # 5 minutes

          end # loop

        end # Imp.run

      end # self.run

    end # class << self

  end # Base
  
end # ImportXml
