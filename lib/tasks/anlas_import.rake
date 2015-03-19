namespace :anlas_import do

  desc 'Обработка выгрузки'
  task :run => :environment do
    ::AnlasImport.run
  end # run

end # anlas_import

# bundle exec rake anlas_import:run
