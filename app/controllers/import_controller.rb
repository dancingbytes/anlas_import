# encoding: utf-8
class ImportController < ApplicationController

  unloadable

  before_filter :auth
  skip_before_filter :verify_authenticity_token, :only => :save_file

  def index

    case params[:mode]
    when 'checkauth'
      render(:text => "success\nimport_1c\n#{rand(9999)}", :layout => false) and return
    when 'init'
      render(:text => "zip=yes\nfile_limit=999999999", :layout => false) and return
    when 'import'
      render(:text => "success", :layout => false) and return
    else
      render(:text => "failure", :layout => false) and return
    end

  end # index

  def save_file

    file_path = File.join(AnlasImport::import_dir, "#{rand}-#{Time.now.to_f}.zip")
    File.open(file_path, 'wb') do |f|
      f.write request.body.read
    end

    render(:text => "success", :layout => false) and return

  end # save_file

  private

  def auth

    authenticate_or_request_with_http_basic do |login, password|
      (login == ::AnlasImport::login && password == ::AnlasImport::password)
    end

  end # auth

end # ImportController
