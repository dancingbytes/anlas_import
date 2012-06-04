# encoding: UTF-8
module AnlasImport

  # Класс-шаблон по разбору товарных xml-файлов
  class XmlParser < Nokogiri::XML::SAX::Document

    def initialize(saver, options = {})

      @options = {
        "price_wholesale" => ["Оптовая", "Оптовые"],
        "price"           => ["Интернет Розничная"],
        "price_bonus_key" => []          # "Бонусная цена"
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

      @price_key = attrs["id"]            if @options["price"].include?(name)
      @price_wholesale_key = attrs["id"]  if @options["price_wholesale"].include?(name)
      @price_bonus_key = attrs["id"]      if @options["price_bonus_key"].include?(name)

    end # tag_price

    def tag_nom(attrs)

      return if attrs["isGroupe"].nil? || attrs["isGroupe"].to_i != 0
      return unless validate_price_key(attrs)

      price       = (attrs[price_bonus_key] && attrs[price_bonus_key].to_i > 0 ? attrs[price_bonus_key] : attrs[price_key]).to_i
      price_old   = (attrs[price_bonus_key] && attrs[price_bonus_key].to_i > 0 ? attrs[price_key] : 0).to_i
      price_wholesale = (attrs[price_wholesale_key] || 0).to_i

      available   = attrs["ostatok"] ? attrs["ostatok"].to_i : 0

      @saver.call(

        # artikul (s)
        attrs["artikul"],

        # artikulprod (s)
        attrs["artikulprod"] || "",

        # name (s)
        attrs["name"],

        # price (i)
        price,

        # price_wholesale (i)
        price_wholesale,

        # price_old (i)
        price_old,

        # available (i)
        available,

        # number_GTD
        (attrs["number_GTD"] || "").gsub(/\-/, ""),

        # sklad
        attrs["sklad"] || ""

      )

    end # tag_nom

    def price_bonus_key
      "price#{@price_bonus_key}"
    end # price_bonus_key

    def price_key
      "price#{@price_key}"
    end # price_key

    def price_wholesale_key
      "price#{@price_wholesale_key}"
    end # price_wholesale_key

    def validate_price_key(attrs)

      if attrs[price_key].nil? || attrs[price_key].empty?
        @errors << "[Errors] Не найдена розничная цена у товара: #{attrs['artikul']}"
        return false
      end
      true

    end # validate_price_key

  end # XmlParser

end # AnlasImport
