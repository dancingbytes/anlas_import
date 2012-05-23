# encoding: UTF-8
module AnlasImport

  # Класс-шаблон по разбору товарных xml-файлов
  class XmlParser < Nokogiri::XML::SAX::Document

    def initialize(saver, options = {})

      @options = {
        "purchasing_price" => ["Оптовая", "Оптовые"]
      }.merge(options)

      #
      @errors = []
      @saver  = saver.respond_to?(:call) ? saver : lambda {}

    end # initialize

    def start_element(name, attrs = [])

      attrs = ::Hash[attrs]

      case name

        when "price" then tag_price(attrs)
        when "nom"   then tag_nom(attrs)

      end # case

    end # start_element

    def error(string)
      @errors << string
    end # error

    def warning(string)
      @errors << string
    end # warning

    def errors
      @errors
    end # errors

    private

    def tag_price(attrs)

      name = attrs["name"]
      @purchasing_price_key = attrs["id"]  if @options["purchasing_price"].include?(name)

    end # tag_price

    def tag_nom(attrs)

      return if attrs["isGroupe"].nil? || attrs["isGroupe"].to_i != 0
      return unless validate_purchasing_price_key(attrs)

      @saver.call(

        # marking_of_goods (s)
        attrs["artikul"],

        # marking_of_goods_manufacturer (s)
        attrs["artikulprod"] || "",

        # name (s)
        attrs["name"],

        # purchasing_price (i)
        attrs[purchasing_price_key],

        # available (i)
        attrs["ostatok"] || 0,

        # gtd_number (s),
        attrs["number_GTD"] || "",

        # storehouse (s)
        attrs["sklad"] || ""

      )

    end # tag_nom

    def purchasing_price_key
      "price#{@purchasing_price_key}"
    end # purchasing_price_key

    def validate_purchasing_price_key(attrs)

      if attrs[purchasing_price_key].nil? || attrs[purchasing_price_key].empty?
        @errors << "[Errors] Не найдена закупочная цена у товара: #{attrs['artikul']}"
        return false
      end
      true

    end # validate_purchasing_price_key

  end # XmlParser

end # AnlasImport
