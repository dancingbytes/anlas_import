# encoding: UTF-8
module AnlasImport

  # Класс-шаблон по разбору товарных xml-файлов
  class XmlParser < Nokogiri::XML::SAX::Document

    def initialize(saver)

      @errors = []
      @saver  = saver
      @price_types = {}
      @item   = {}

      @level  = 0
      @tags   = {}

    end # initialize

    def start_element(name, attrs = [])

      attrs  = ::Hash[attrs]
      @str   = ""

      @level += 1
      @tags[@level] = name

      case name

        # 1C 7.7
        when "nom"          then tag_nom(attrs)

        # 1C 8
        when "ТипЦены"      then start_parse_price
        when "Предложение"  then start_parse_item
        when "Цена"         then start_parse_item_price

        when "БазоваяЕдиница" then
          @item["unit_code"] = (attrs["Код"] || "").clean_whitespaces if @start_parse_item

      end # case

    end # start_element

    def end_element(name)

      @level -= 1

      case name

        when "Ид" then
          @price_id  = @str  if for_price?
          grub_item("code_1c")

        when "Наименование"  then
          @price_name = @str if for_price?
          grub_item("name")

        when "Отдел"        then grub_item("department")
        when "Штрихкод"     then grub_item("bar_code")
        when "Артикул"      then grub_item("marking_of_goods")

        when "КодСтранаПроисхождения" then grub_item("country_code")
        when "СтранаПроисхождения"    then grub_item("country")

        when "НомерГТД"     then grub_item("gtd_number")
        when "Количество"   then grub_item("available")

        when "БазоваяЕдиница" then grub_item("unit")

        when "ЦенаЗаЕдиницу"  then
          @item_price = @str  if for_item_price?

        when "ИдТипаЦены"   then
          @item_price_id = @str  if for_item_price?

        when "ТипЦены"      then stop_parse_price
        when "Предложение"  then stop_parse_item
        when "Цена"         then stop_parse_item_price

      end # case

    end # end_element

    def characters(str)
      @str << str.clean_whitespaces unless str.blank?
    end # characters

    def error(string)
      @errors << "[Errors] #{string}"
    end # error

    def warning(string)
      @errors << "[Warnings] #{string}"
    end # warning

    def errors
      @errors
    end # errors

    private

    def parent_tag
      @tags[@level] || ""
    end # parent_tag

    def for_item?
      (@start_parse_item && parent_tag == "Предложение")
    end # for_item?

    def for_price?
      (@parse_price && parent_tag == "ТипЦены")
    end # for_price?

    def for_item_price?
      (@start_parse_item_price && parent_tag == "Цена")
    end # for_item_price?

    def grub_item(attr_name)
      @item[attr_name] = @str if for_item?
    end # grub_item

    def save_item(attrs)

      @saver.load(

        # Идентификатор в 1с (i)
        # code_1c
        attrs["id"] || attrs["code_1c"],

        # Отдел (s)
        attrs["department"],

        # marking_of_goods (s)
        (attrs["artikul"] || attrs["marking_of_goods"]).clean_whitespaces,

        # marking_of_goods_manufacturer (s)
        (attrs["artikulprod"] || "").clean_whitespaces,

        # name (s)
        attrs["name"].clean_whitespaces,

        # Цена закупа поставщика
        # supplier_purchasing_price (f)
        (attrs["price_zakup"] || attrs["supplier_purchasing_price"]).try(:to_f) || 0,

        # Оптовая цена поставщика
        # supplier_wholesale_price (i)
        (attrs["price_opt"] || attrs["supplier_wholesale_price"]).try(:to_i) || 0,

        # Цена закупа интернет-магазина
        # purchasing_price (i)
        (attrs["price_kontr"] || attrs["purchasing_price"]).try(:to_i) || 0,

        # Наличие (остатки)
        # available (i)
        (attrs["ostatok"] || attrs["available"]).try(:to_i) || 0,

        # Страна призводитель
        # country (s)
        (attrs["country"] || "").gsub(/\-/, ""),

        # Код страны производителя
        # country_code (i)
        (attrs["country_kod"] || attrs["country_code"]).try(:to_i) || 0,

        # Склад
        # storehouse (s)
        attrs["sklad"] || attrs["storehouse"] || "",

        # Штрих-код
        # bar_code (s)
        attrs["shtrih_kod"] || attrs["bar_code"] || "",

        # Вес в килограммах
        # weight (f)
        (attrs["ves"] || attrs["weight"]).try(:to_i) || 0,

        # gtd_number (s)
        (attrs["number_GTD"] || attrs["gtd_number"] || "").gsub(/\-/, ""),

        # Название товарной единицы
        # unit (s)
        attrs["ed"] || attrs["unit"] || "",

        # Код товарной единицы
        # unit_code (i)
        (attrs["okei"] || attrs["unit_code"]).try(:to_i) || 0

      )

    end # save_item

    #
    # 1C 7.7
    #

    def tag_nom(attrs)
      save_item(attrs) if validate_1c_77(attrs)
    end # tag_nom

    def validate_1c_77(attrs)

      return if attrs["isGroupe"].nil? || attrs["isGroupe"].to_i != 0

      if attrs['id'].blank?
        @errors << "[Errors 1C 7.7] Не найден идентификатор у товара: #{attrs['artikul']}"
        return false
      end

      if attrs['department'].blank?
        @errors << "[Errors 1C 7.7] Не найден поставщик у товара: #{attrs['artikul']}"
        return false
      end

      if attrs['name'].blank?
        @errors << "[Errors 1C 7.7] Не найдено название у товара: #{attrs['artikul']}"
        return false
      end

      if attrs['artikul'].blank?
        @errors << "[Errors 1C 7.7] Не найден артикул у товара: #{attrs['name']}"
        return false
      end

      if attrs['price_zakup'].blank?
        @errors << "[Errors 1C 7.7] Не найдена закупочная цена у товара: #{attrs['artikul']} - #{attrs['name']}"
        return false
      end

      if attrs['price_opt'].blank?
        @errors << "[Errors 1C 7.7] Не найдена оптовая цена у товара: #{attrs['artikul']} - #{attrs['name']}"
        return false
      end

      if attrs['price_kontr'].blank?
        @errors << "[Errors 1C 7.7] Не найдена цена у товара: #{attrs['artikul']} - #{attrs['name']}"
        return false
      end

      true

    end # validate_prices_1c_77

    #
    # 1C 8
    #

    def start_parse_price
      @parse_price = true
    end # start_parse_price

    def stop_parse_price

      if !@price_name.blank? && !@price_id.blank?
        @price_types[@price_id] = @price_name
      end

      @price_name   = nil
      @price_id     = nil
      @parse_price  = false

    end # stop_parse_price

    def start_parse_item

      @start_parse_item = true
      @item = {}

    end # start_parse_item

    def stop_parse_item

      save_item(@item) if validate_1c_8(@item)

      @start_parse_item = false
      @item = {}

    end # start_parse_item

    def start_parse_item_price
      @start_parse_item_price = true
    end # start_parse_item_price

    def stop_parse_item_price

      if !@item_price.blank? && !@item_price_id.blank?

        case @price_types[@item_price_id]

          when "Опт" then
            @item["supplier_wholesale_price"] = @item_price

          when "Закупочная" then
            @item["supplier_purchasing_price"] = @item_price

          when "Интернет розничная" then
            @item["purchasing_price"] = @item_price

        end # case

      end # if

      @item_price     = nil
      @item_price_id  = nil
      @start_parse_item_price = false

    end # stop_parse_item_price

    def validate_1c_8(attrs)

      if attrs['code_1c'].blank?
        @errors << "[Errors 1C 8] Не найден идентификатор у товара: #{attrs['marking_of_goods']}"
        return false
      end

      if attrs['department'].blank?
        @errors << "[Errors 1C 8] Не найден поставщик у товара: #{attrs['marking_of_goods']}"
        return false
      end

      if attrs['name'].blank?
        @errors << "[Errors 1C 8] Не найдено название у товара: #{attrs['marking_of_goods']}"
        return false
      end

      if attrs['marking_of_goods'].blank?
        @errors << "[Errors 1C 8] Не найден артикул у товара: #{attrs['name']}"
        return false
      end

      if attrs['supplier_purchasing_price'].blank?
        @errors << "[Errors 1C 8] Не найдена закупочная цена у товара: #{attrs['marking_of_goods']} - #{attrs['name']}"
        return false
      end

      if attrs['supplier_wholesale_price'].blank?
        @errors << "[Errors 1C 8] Не найдена оптовая цена у товара: #{attrs['marking_of_goods']} - #{attrs['name']}"
        return false
      end

      if attrs['purchasing_price'].blank?
        @errors << "[Errors 1C 8] Не найдена цена у товара: #{attrs['marking_of_goods']} - #{attrs['name']}"
        return false
      end

      true

    end # validate_1c_8

  end # XmlParser

end # AnlasImport
