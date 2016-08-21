class AnlasImportWorker

  include SidekiqStatus::Worker

  sidekiq_options queue: :default, retry: false, backtrace: false

  def perform(file_path)

    ::AnlasImport::Manager.run(file_path)
    nil

  end # perform

end # AnlasImportWorker
