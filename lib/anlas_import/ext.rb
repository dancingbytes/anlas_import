# encoding: utf-8
require 'unicode'

module AnlasImport

  module StringExt

    def utf8

      self.force_encoding(::Encoding::UTF_8) if self.respond_to?(:force_encoding)
      self

    end # utf8

    def escape

      str = self.gsub(/'/, "\\\\'")
      str.gsub!(/"/, '\\\\"')
      str.gsub!(/\n/, "\\n")
      str.gsub!(/\r/, "\\r")
      str

    end # escape

  end # StringExt

  module NilExt

    def utf8
      self
    end # utf8

  end # NilExt

end # AnlasImport

class String

  include ::AnlasImport::StringExt

  class_eval '

    def downcase
      Unicode::downcase(self)
    end # downcase

    def downcase!
      self.replace downcase
    end # downcase!

    def upcase
      Unicode::upcase(self)
    end # upcase

    def upcase!
      self.replace upcase
    end # upcase!

    def capitalize
      Unicode::capitalize(self)
    end # capitalize

    def first_capitalize

      str     = self
      str[0]  = Unicode::capitalize(str[0] || "")
      str

    end # first_capitalize

    def capitalize!
      self.replace capitalize
    end # capitalize!

    def first_capitalize!
      self.replace first_capitalize
    end # first_capitalize
  '

end # String

class NilClass
  include ::AnlasImport::NilExt
end
