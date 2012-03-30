# encoding: utf-8
require 'net/smtp'

module Net

  class InternetMessageIO

    private

    def each_crlf_line(src)
      
      buffer_filling(@wbuf, src) do
        
        while line = @wbuf.slice!(/\A.*(?:\n|\r\n|\r(?!\z))/u)
          yield line.chomp("\n") + "\r\n"
        end

      end # do

    end # each_crlf_line

  end # InternetMessageIO  

end # Net

module AnlasImport

  class Mailer

    def initialize(config = {})

      @config = {
        :from       => "robot@anlas.ru",
        :from_alias => "robot",
        :to         => "piliaiev@gmail.com", #"info@v-avto.ru",
        :to_alias   => "admin",
        :domain     => "localhost",
        :port       => 25
      }.merge(config)

    end # initialize

    def send_message(subject, message)

      msg = "From: #{@config[:from_alias]} <#{@config[:from]}>\r\n"
      msg << "To: #{@config[:to_alias]} <#{@config[:to]}>\r\n"
      msg << "Subject: #{subject.utf8}\r\n"
      msg << "Content-Type: text/plain; charset=utf-8\r\n"
      msg << "MIME-Version: 1.0\r\n"
      msg << "Date: #{::Time.now.strftime('%H:%M:%S %d-%m-%Y')}\r\n"

      msg << "\r\n#{message.utf8}\r\n"
      
      ::Net::SMTP.start(@config[:domain], @config[:port]) do |smtp|
        smtp.send_message(msg, @config[:from], @config[:to])
      end

    end # send_message

  end # Mailer

end # AnlasImport