# encoding: UTF-8
module AnlasImport

  # Сохранение данных (добавление новых, обновление сущестующих), полученных
  # при разборе xml-файла.
  class Worker

    def initialize(file)

      @errors, @file  = [], file
      @ins, @upd      = 0, 0
      @file_name      = ::File.basename(@file)

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

    def load(

      code_1c,
      department,

      marking_of_goods,
      marking_of_goods_manufacturer,

      name,

      supplier_purchasing_price,
      supplier_wholesale_price,
      purchasing_price,

      available,

      country,
      country_code,

      storehouse,
      bar_code,

      weight,

      gtd_number,
      unit,
      unit_code

      )

      # Код поставщика
      supplier_code = suppliers[department.downcase]

      # Если код поставщика не найден -- завершаем работу
      if supplier_code.nil?
        @errors << "[Errors] Поставщик (#{department}) не зарегистрирован в системе. Товар: #{marking_of_goods} -> #{name}"
        return
      end

      if (item = find_item(supplier_code, code_1c, marking_of_goods))

        # Если товар по заданным параметрам существует -- обновляем его.
        update_item(
          item,
          code_1c,
          supplier_code,
          marking_of_goods,
          marking_of_goods_manufacturer,
          name,
          supplier_purchasing_price,
          supplier_wholesale_price,
          purchasing_price,
          available,
          country,
          country_code,
          storehouse,
          bar_code,
          weight,
          gtd_number,
          unit,
          unit_code
        )

      else

        # Иначе -- создаем новый товар.
        insert_item(
          code_1c,
          supplier_code,
          marking_of_goods,
          marking_of_goods_manufacturer,
          name,
          supplier_purchasing_price,
          supplier_wholesale_price,
          purchasing_price,
          available,
          country,
          country_code,
          storehouse,
          bar_code,
          weight,
          gtd_number,
          unit,
          unit_code
        )

      end # if

    end # load

    private

    def work_with_file

      suppliers

      pt = ::AnlasImport::XmlParser.new(self)

      parser = ::Nokogiri::XML::SAX::Parser.new(pt)
      parser.parse_file(@file)

      unless (errors = pt.errors).empty?
        @errors << errors
      end

      begin

        if ::AnlasImport::backup_dir && ::FileTest.directory?(::AnlasImport::backup_dir)
          ::FileUtils.mv(@file, ::AnlasImport.backup_dir)
        end

      rescue SystemCallError
        puts "Не могу переместить файл `#{@file_name}` в `#{::AnlasImport.backup_dir}`"
      ensure
        ::FileUtils.rm_rf(@file)
      end

    end # work_with_file

    def suppliers

      return @suppliers if @suppliers

      @suppliers = {}

      ::Supplier.only(:name, :code).each do |suppl|
        @suppliers[suppl.name.downcase] = suppl.code
      end

      @suppliers

    end # suppliers

    def find_item(supplier_code, code_1c, marking_of_goods)

      item = ::Item.only(

        :code_1c,
        :supplier_code,
        :marking_of_goods,
        :marking_of_goods_manufacturer,
        :name,

        :supplier_purchasing_price,
        :supplier_wholesale_price,
        :purchasing_price,

        :available,
        :country,
        :country_code,
        :storehouse,
        :bar_code,
        :weight,
        :gtd_number,
        :unit,
        :unit_code,

        :price_type_rate,
        :sale_rate,
        :for_sale

      )

      item.any_of({
        supplier_code:  supplier_code,
        code_1c:        code_1c
      }, {
        marking_of_goods: marking_of_goods
      }).first

    end # find_item

    def insert_item(

      code_1c,
      supplier_code,
      marking_of_goods,
      marking_of_goods_manufacturer,
      name,
      supplier_purchasing_price,
      supplier_wholesale_price,
      purchasing_price,
      available,
      country,
      country_code,
      storehouse,
      bar_code,
      weight,
      gtd_number,
      unit,
      unit_code

      )

      item                                = ::Item.new

      item.code_1c                        = code_1c
      item.supplier_code                  = supplier_code
      item.marking_of_goods               = marking_of_goods
      item.marking_of_goods_manufacturer  = marking_of_goods_manufacturer
      item.name_1c                        = name
      item.supplier_purchasing_price      = supplier_purchasing_price
      item.supplier_wholesale_price       = supplier_wholesale_price
      item.purchasing_price               = purchasing_price
      item.available                      = available
      item.country                        = country
      item.country_code                   = country_code
      item.storehouse                     = storehouse
      item.bar_code                       = bar_code
      item.weight                         = weight
      item.gtd_number                     = gtd_number
      item.unit                           = unit
      item.unit_code                      = unit_code

      item.imported_at                    = ::Time.now.utc

      item.unmanaged                      = true
      item.public                         = true
      item.name                           = name
      item.meta_title                     = name

      if item.save(validate: false)
        @ins += 1
        true
      else
        @errors << "[INSERT] (#{supplier_code}-#{code_1c}: #{marking_of_goods}) #{item.errors.inspect}"
        false
      end

    end # insert_item

    def update_item(

      item,

      code_1c,
      supplier_code,
      marking_of_goods,
      marking_of_goods_manufacturer,
      name,
      supplier_purchasing_price,
      supplier_wholesale_price,
      purchasing_price,
      available,
      country,
      country_code,
      storehouse,
      bar_code,
      weight,
      gtd_number,
      unit,
      unit_code

      )

      item.code_1c                        = code_1c
      item.supplier_code                  = supplier_code
      item.marking_of_goods               = marking_of_goods
      item.marking_of_goods_manufacturer  = marking_of_goods_manufacturer
      item.name_1c                        = name
      item.supplier_purchasing_price      = supplier_purchasing_price
      item.supplier_wholesale_price       = supplier_wholesale_price
      item.purchasing_price               = purchasing_price
      item.available                      = available
      item.country                        = country
      item.country_code                   = country_code
      item.storehouse                     = storehouse
      item.bar_code                       = bar_code
      item.weight                         = weight
      item.gtd_number                     = gtd_number
      item.unit                           = unit
      item.unit_code                      = unit_code

      item.imported_at                    = ::Time.now.utc

      if item.save(validate: false)
        @upd += 1
        true
      else
        @errors << "[UPDATE] (#{supplier_code}-#{code_1c}: #{marking_of_goods}) #{item.errors.inspect}"
        false
      end

    end # update_item

  end # Worker

end # AnlasImport
