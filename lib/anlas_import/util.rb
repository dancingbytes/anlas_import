# encoding: utf-8
module AnlasImport

  module Util

    extend self

    def xml_unescape(str)

      str2 = str.gsub(/&apos;/, "'")
      str2.gsub!(/&quot;/, '"')
      str2.gsub!(/&gt;/, ">")
      str2.gsub!(/&lt;/, "<")
      str2

    end # xml_unescape

  end # Util

end # AnlasImport
