namespace :topical_map_to_kmaps do
  namespace :db do
    desc "Prepare db"
    task :prepare do
      Rake::Task['db:drop'].invoke
      Rake::Task['db:create'].invoke
      Rake::Task['kmaps_engine:db:schema:load'].invoke
      Rake::Task['kmaps_engine:db:seed'].invoke
      Rake::Task['subjects_engine:db:seed'].invoke
    end
    desc "Run importation"
    task :import => :environment do
      TopicalMapToKmaps.run_importation    
    end
    desc "Run importation of categories and descriptions"
    task :import_categories => :environment do
      TopicalMapToKmaps.import_categories
    end
    desc "Run importation of category relations"
    task :import_relations => :environment do
      TopicalMapToKmaps.import_relations
    end
    desc "Run after_update and after_create triggers for all features"
    task :handle_triggers => :environment do
      TopicalMapToKmaps.handle_triggers
    end
  end
end