# encoding: UTF-8
module AnlasImport

  # Сохранение данных (добавление новых, обновление сущестующих), полученных
  # при разборе xml-файла.
  class Worker

    def initialize(file, conn)

      @errors, @ins, @upd = [], 0, []
      @file, @conn = file, conn

      unless @file && ::FileTest.exists?(@file)
        @errors << "Файл не найден: #{@file}\n"
      else
        @errors << "Не могу соединиться с базой данных!" unless @conn
      end # unless
      
    end # new

    def parse

      work_with_file if @errors.empty?
      self

    end # parse_file

    def errors
      @errors
    end # report

    def updated
      @upd
    end # updated
    
    def inserted
      @ins
    end # insert

    private

    def init_saver(catalog)

      # Блок сохраниения данных в базу
      @saver = lambda { |artikul, artikulprod, name, price, price_wholesale, price_old, in_order|
                        
        name = name.strip.escape
        artikul = artikul.strip.escape
        artikulprod = artikulprod.strip.escape

        # Проверка товара на наличие букв "яя" вначле названия (такие товары не выгружаем)
        unless skip_by_name(name)

          if target_exists(artikul)
            @upd << artikul if update(name, price, price_wholesale, price_old, in_order, artikulprod, artikul)
          else
            @ins += 1 if insert(name, price, price_wholesale, price_old, in_order, artikulprod, artikul, catalog)
          end

        end # unless

      } # saver

    end # init_saver

    def work_with_file

      unless (catalog = catalog_for_import( prefix_file ))
       @errors << "Каталог выгрузки не найден! Файл: #{@file}"
      else

        init_saver(catalog)

        pt = ::AnlasImport::XmlParser.new(@saver)

        parser = ::Nokogiri::XML::SAX::Parser.new(pt)
        parser.parse_file(@file)

        unless (errors = pt.errors).empty?
          @errors << errors
        end
        
        ::FileUtils.rm_rf(@file)

      end # unless

    end # work_with_file

    def catalog_for_import(prefix)
      
      catalog_import = @conn.collection("catalogs").find_one({
        "import_prefix" => (prefix.blank? ? "_" : prefix)
      })
      
      catalog_import ? catalog_import["_id"] : false
      
    end # catalog_for_import

    def target_exists(marking_of_goods)
      
      item = @conn.collection("items").find_one({
        "marking_of_goods" => marking_of_goods
      })
      
      item ? item : false

    end # target_exists

    def insert(name, price, price_wholesale, price_old, in_order, artikulprod, artikul, collector_id)
      
      doc = {
        "name" => name,
        "price" => price,
        "price_wholesale" => price_wholesale,
        "price_old" => price_old,
        "marking_of_goods" => artikul,
        "available" => in_order,
        "marking_of_goods_manufacturer" => artikulprod,
        "meta_title" => name,
        "meta_description" => name,
        "imported_at" => ::Time.now.utc,
        "created_at" => ::Time.now.utc
      }
      
      opts = {:safe => true}
       
      begin
        @conn.collection("items").insert(doc, opts)
        return true
      rescue => e
        @errors << "#{e}"
        return false
      end # begin
      
    end # insert

    def update(name, price, price_wholesale, price_old, in_order, artikulprod, artikul)
      
      selector = {"marking_of_goods" => artikul}
        
      doc = {
        "name" => name,
        "price" => price,
        "price_wholesale" => price_wholesale,
        "price_old" => price_old,
        "available" => in_order,
        "marking_of_goods_manufacturer" => artikulprod,
        "meta_title" => name,
        "meta_description" => name,
        "imported_at" => ::Time.now.utc
      }
      
      opts = {:safe => true}
       
      begin
        @conn.collection("items").update(selector, doc, opts)
        return true
      rescue => e
        @errors << "#{e}"
        return false
      end # begin
      
    end # update

    def skip_by_name(name)
      (name =~ /^я{2,}/u) === 0
    end # skip_by_name

    def prefix_file
      ::File.basename(@file).scan(/^([a-z]+)_/).flatten.first || ""
    end # prefix_file

  end # Worker

end # AnlasImport