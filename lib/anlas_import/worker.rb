# encoding: UTF-8
module AnlasImport

  # Сохранение данных (добавление новых, обновление сущестующих), полученных
  # при разборе xml-файла.
  class Worker

    def initialize(file)

      @catalogs = {}

      @errors, @ins, @upd, @file = [], [], [], file
      @file_name = ::File.basename(@file)

      unless @file && ::FileTest.exists?(@file)
        @errors << "Файл не найден: #{@file}"
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

    def init_saver#(catalog)

      # Блок сохраниения данных в базу
      @saver = lambda { |artikul, artikulprod, name, price, purchasing_price, price_old, available, gtd_number, storehouse|

        name        = clear_name(name).strip.escape
        artikul     = artikul.strip.escape
        artikulprod = artikulprod.strip.escape
        postfix     = artikul[-1] || ""

        # Проверка товара на наличие букв "яя" вначле названия (такие товары не выгружаем)
        unless skip_by_name(name)

          if item = find_item(artikul, postfix)

            if update(item, artikul, artikulprod, name, price, purchasing_price, price_old, available, gtd_number, storehouse)
              @upd << artikul
            end

          else

            if catalog = catalog_for_import(postfix)

              if insert(catalog, artikul, artikulprod, name, price, purchasing_price, price_old, available, gtd_number, storehouse)
                @ins << artikul
              end

            else
              @errors << "[Errors] Каталог выгрузки не найден. Товар: #{artikul} -> #{name} (postfix: #{postfix})"
            end # if

          end # if

        end # unless

      } # saver

    end # init_saver

    def work_with_file

      init_saver

      pt = ::AnlasImport::XmlParser.new(@saver)

      parser = ::Nokogiri::XML::SAX::Parser.new(pt)
      parser.parse_file(@file)

      unless (errors = pt.errors).empty?
        @errors << errors
      end

      begin
        ::FileUtils.mv(@file, ::AnlasImport::Base.backup_dir)
      rescue SystemCallError
        puts "Не могу переместить файл `#{@file_name}` в `#{::AnlasImport::Base.backup_dir}`"
        ::FileUtils.rm_rf(@file)
      end

    end # work_with_file

    def catalog_for_import(postfix)

      unless (catalog = @catalogs[postfix])

        catalog = ::Catalog.safely.where(:import => postfix).first
        @catalogs[postfix] = catalog if catalog

      end # unless

      catalog

    end # catalog_for_import

    def find_item(marking_of_goods, postfix)

      item = ::Item.where(:marking_of_goods => marking_of_goods).first
      return item if item

      marking_of_goods_old = ::AnlasImport::TABLE_MATCHES[postfix] + marking_of_goods[0, marking_of_goods.length-1]
      ::Item.where(:marking_of_goods_old => marking_of_goods_old).first

    end # find_item

    def insert(catalog, artikul, artikulprod, name, price, purchasing_price, price_old, available, gtd_number, storehouse)

      item = ::Item.new

      item.marking_of_goods = artikul
      item.marking_of_goods_manufacturer = artikulprod

      item.catalog_id = catalog.id
      item.name_1c    = name
      item.name       = name
      item.meta_title = name
      item.unmanaged  = true

      item.price      = price
      item.price_wholesale  = purchasing_price
      item.purchasing_price = purchasing_price
      item.price_old  = price_old

      item.available  = available
      item.gtd_number = gtd_number
      item.storehouse = storehouse

      item.imported_at  = ::Time.now.utc

      unless item.save(validate: false)
        @errors << "[INSERT: #{artikul}] #{item.errors.inspect}"
        return false
      end

      true

    end # insert

    def update(item, artikul, artikulprod, name, price, purchasing_price, price_old, available, gtd_number, storehouse)

      item.marking_of_goods      = artikul
      item.marking_of_goods_manufacturer  = artikulprod

      item.name_1c      = name

      item.price        = price
      item.price_wholesale  = purchasing_price
      item.purchasing_price = purchasing_price
      item.price_old    = price_old

      item.available    = available
      item.gtd_number   = gtd_number
      item.storehouse   = storehouse

      item.imported_at  = ::Time.now.utc

      unless item.save(validate: false)
        @errors << "[UPDATE: #{artikul}] #{item.errors.inspect}"
        return false
      end

      true

    end # update

    def skip_by_name(name)
      (name =~ /^я{2,}/u) === 0
    end # skip_by_name

    def clear_name(name)

      name
        .sub(/\A\s+/, "")
        .gsub(/\!{0,}\z/i, "")
        .gsub(/акция/i, "")
        .gsub(/подарок/i, "")
        .gsub(/не заказывать/i, "")
        .gsub(/снижена цена/i, "")
        .gsub(/\(\)/, "")
        .gsub(/\s{0,}\+\s{0,}\z/, "")
        .gsub(/(\s){2,}/, '\\1')
        .sub(/\s+\z/, "")

    end # clear_name

    def prefix_file
      @file_name.scan(/^([a-z]+)_/).flatten.first || ""
    end # prefix_file

  end # Worker

end # AnlasImport
