# encoding: UTF-8
module AnlasImport

  # Сохранение данных (добавление новых, обновление сущестующих), полученных
  # при разборе xml-файла.
  class Worker

    def self.parse(file)
      new(file).parse
    end # self.parse

    def initialize(file)

      @file         = file
      @ins, @upd    = 0, 0
      @file_name    = ::File.basename(@file)
      @departments  = {}
      @skip_file    = false

    end # new

    def parse

      log "[#{Time.now.strftime('%H:%M:%S %d-%m-%Y')}] Обработка файлов импорта ============================"

      unless @file && ::FileTest.exists?(@file)
        log "Файл не найден: #{@file}"
      else

        log "Файл: #{@file}"

        start = Time.now.to_i

        work_with_file

        if skip_file?
          log "Файл не используется для обработки. Удален."
        else

          log "[Обработаны отделы] #{@departments.values.join('. ')}."
          log "Товаров: "
          log "   добавлено: #{@ins}"
          log "   обновлено: #{@upd}"

          log "Затрачено времени: #{ '%0.3f' % (Time.now.to_f - start) } сек."

        end

      end

      log ""

      self

    end # parse_file

    def skip_file!
      @skip_file = true
    end # skip_file!

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
      unit_code,

      brand_name

      )

      # Код поставщика
      supplier_code = ::AnlasImport.supplier_code(department)

      # Если код поставщика не найден -- завершаем работу
      if supplier_code.nil?
        log "[Errors] Поставщик (#{department}) не зарегистрирован в системе. Товар: #{marking_of_goods} -> #{name}"
        return
      end

      # Запоминаем отделы
      @departments[supplier_code] ||= department

      unless (item = find_item(supplier_code, code_1c, marking_of_goods)).nil?

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
          unit_code,
          brand_name
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
          unit_code,
          brand_name
        )

      end # if

    end # load

    def log(msg)
      ::AnlasImport.log(msg)
    end # log

    private

    def skip_file?
      @skip_file == true
    end # skip_file

    def work_with_file

      pt = ::AnlasImport::XmlParser.new(self)

      parser = ::Nokogiri::XML::SAX::Parser.new(pt)
      parser.parse_file(@file)

      if @skip_file

        begin
          ::FileUtils.rm_rf(@file)
        rescue
        end

      else
        ::AnlasImport.backup_file_to_dir(@file)
      end

    end # work_with_file

    def find_item(supplier_code, code_1c, marking_of_goods)

      ::Item.where({
        supplier_code:  supplier_code,
        code_1c:        code_1c
      }).first || ::Item.where({
        supplier_code:    supplier_code,
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
      unit_code,
      brand_name

      )

      item                                = ::Item.new

      item.code_1c                        = code_1c
      item.supplier_code                  = supplier_code
      item.marking_of_goods               = marking_of_goods || ""
      item.marking_of_goods_manufacturer  = marking_of_goods_manufacturer || ""
      item.name_1c                        = name

      item.supplier_purchasing_price      = supplier_purchasing_price
      item.supplier_wholesale_price       = supplier_wholesale_price
      item.purchasing_price               = purchasing_price

      item.available                      = available.try(:to_i) || 0
      item.country                        = country       || ""
      item.country_code                   = country_code  || ""
      item.storehouse                     = storehouse    || ""
      item.bar_code                       = bar_code      || ""
      item.weight                         = weight        || 0
      item.gtd_number                     = gtd_number    || ""
      item.unit                           = unit          || ""
      item.unit_code                      = unit_code     || 0

      item.imported_at                    = ::Time.now.utc

      item.managed                        = false
      item.name                           = name
      item.meta_title                     = name

      unless brand_name.blank?

        if (brand = ::Brand.find_or_create_by({ name: brand_name }))
          item.brand_id  = brand.id
        end

      end # unless

      if item.save(validate: false)
        @ins += 1
        true
      else
        log "[INSERT] (#{supplier_code}-#{code_1c}: #{marking_of_goods}) #{item.errors.inspect}"
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
      unit_code,
      brand_name

      )

      begin

        item.set(:code_1c, code_1c)
        item.set(:supplier_code, supplier_code)
        item.set(:marking_of_goods, marking_of_goods)  unless marking_of_goods.blank?
        item.set(:marking_of_goods_manufacturer, marking_of_goods_manufacturer) unless marking_of_goods_manufacturer.nil?
        item.set(:name_1c, name)

        item.set(:supplier_purchasing_price, supplier_purchasing_price) # if supplier_purchasing_price > 0
        item.set(:supplier_wholesale_price, supplier_wholesale_price)   # if supplier_wholesale_price > 0
        item.set(:purchasing_price, purchasing_price)                   # if purchasing_price > 0

        item.set(:country, country)             unless country.nil?
        item.set(:country_code, country_code)   unless country_code.nil?
        item.set(:storehouse, storehouse)       unless storehouse.nil?
        item.set(:bar_code, bar_code)           unless bar_code.nil?
        item.set(:weight, weight)               unless weight.nil?
        item.set(:gtd_number, gtd_number)       unless gtd_number.nil?
        item.set(:unit, unit)                   unless unit.nil?
        item.set(:unit_code, unit_code)         unless unit_code.nil?

        item.set(:imported_at, ::Time.now.utc)
        item.set(:available, available.try(:to_i) || 0) unless available.blank?

        item.update_sphinx

        @upd += 1
        true

      rescue => ex
        log "[UPDATE] (#{supplier_code}-#{code_1c}: #{marking_of_goods}) #{ex.inspect}"
        false
      end

    end # update_item

  end # Worker

end # AnlasImport
