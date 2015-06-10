require "topical_map_to_kmaps/engine"

module TopicalMapToKmaps
  def self.topical_map_database_yaml
    settings = Rails.cache.fetch('topical_map/database.yml/hash', :expires_in => 1.day) do
      settings_file = Rails.root.join('config', 'topical_map_database.yml')
      settings_file.exist? ? YAML.load_file(settings_file) : {}
    end
    settings[Rails.env]
  end
  
  def self.run_importation
    categories = TopicalMap::Category.order(:id)
    self.import_categories(categories)
    self.import_relations(categories)
    self.handle_triggers
  end
  
  def self.import_relations(categories = TopicalMap::Category.order(:id))
    puts 'Importing category relations'
    general = Perspective.get_by_code('gen')
    categories.each do |c|
      puts "Importing category relations for #{c.id}"
      if !c.parent_id.nil?
        child_id = Feature.get_by_fid(c.id).id
        parent_id = Feature.get_by_fid(c.parent_id).id
        FeatureRelation.create(:child_node_id => child_id, :parent_node_id => parent_id, :perspective_id => general.id, :feature_relation_type_id => c.cumulative? ? FeatureRelationType.get_by_code('is.part.of').id : FeatureRelationType.get_by_code('is.an.instantiation.of').id, :skip_update => true) if FeatureRelation.where(:child_node_id => child_id, :parent_node_id => parent_id).empty?
      end
    end
  end
  
  def self.import_categories(categories = TopicalMap::Category.order(:id))
    puts 'Importing authors'
    authors = TopicalMap::Person.select('author_id').uniq('author_id').from('authors_descriptions').collect{|a| TopicalMap::Person.find(a.author_id).fullname.strip}
    authors.each { |fullname| AuthenticatedSystem::Person.create(:fullname => fullname) if AuthenticatedSystem::Person.find_by(fullname: fullname).nil? } 
    
    categories.each do |c|
      puts "Importing categories names and descriptions for #{c.id}"
      f = Feature.find_by(fid: c.id)
      f = Feature.create(:is_public => c.published?, :fid => c.id) if f.nil?
      self.import_names(c, f)
      self.import_descriptions(c, f)
    end
  end
  
  def self.handle_triggers
    Feature.order(:fid).each do |f|
      puts "Updating cached feature names for #{f.fid}"
      f.update_cached_feature_names
    end
    Feature.order(:fid).each do |f|
      puts "Expiring cache for #{f.fid}"
      #Rails.cache.write('tree_tmp', f.id)
      f.expire_tree_cache
    end
    Feature.order(:fid).each do |f|
      puts "Updating hierarchy for #{f.fid}"
      f.update_hierarchy
    end
    Feature.order(:fid).each do |f|
      puts "Updating name positions for #{f.fid}"
      f.update_name_positions
    end
  end
  
  private
  
  def self.import_descriptions(c, f)
    c.descriptions.order(:id).each do |d|
      next if !Description.where(:feature_id => f.id, :title => d.title).empty?
      desc = f.descriptions.create :title => d.title, :is_primary => d.is_main?, :content => d.content, :author_ids => d.authors.collect{ |a| AuthenticatedSystem::Person.find_by(fullname: a.fullname.strip).id }
      d.sources.each do |s|
        note = s.note.nil? ? '' : s.note
        if !s.passage.blank?
          note << "\n" if !note.blank?
          note << "<p>Passage (#{self.kmaps_language(s.language_id).name})</p>\n"
          note << s.passage
          s.translated_sources.each do |ts|
            note << "<p>Translation (#{self.kmaps_language(ts.language_id).name})</p>\n"
            note << ts.title
          end
        end
        cit = desc.citations << Citation.create(:info_source_id => s.mms_id, :notes => note)
        cit.pages << Page.create(:volume => s.volume_number, :start_page => s.start_page, :start_line => s.start_line, :end_page => s.end_page, :end_line => s.end_line) if !s.volume_number.nil? || !s.start_page.nil? || !s.start_line.nil? || !s.end_page.nil? || !s.end_line.nil?
      end
    end
  end
  
  def self.import_names(c, f)
    names = f.names
    main_name = names.find_by(name: c.title)
    main_name = names.create(:name => c.title, :language_id => Language.get_by_code('eng').id, :writing_system_id => WritingSystem.get_by_code('latin').id, :is_primary_for_romanization => true, :skip_update => true) if main_name.nil?
    pending_relations = []
    c.translated_titles.order(:id).each do |t|
      language_id = t.language.id
      next if !names.find_by(name: t.title).nil?
      name = names.create(:name => t.title, :language_id => self.kmaps_language(language_id).id, :writing_system_id => self.writing_system(language_id).id, :skip_update => true)
      case language_id
      when 1, 2, 3, 4, 8, 14, 9, 13, 17  # English, Tibetan, Dzongkha, Nepali, Sanskrit, Sanskrit-Transliterated, Chinese-Traditional, Chinese-Simplified, Tibetan (Amdo)
        FeatureNameRelation.create :parent_node_id => main_name.id, :child_node_id => name.id, :is_translation => true, :skip_update => true
      else
        pending_relations << {:type => language_id, :name => name}
      end
    end
    pending_relations.each do |r|
      name = r[:name]
      case r[:type]
      when 10 # Chinese-Pinyin
        parent = names.where(:language_id => Language.get_by_code('zho').id, :writing_system_id => [WritingSystem.get_by_code('hant').id, WritingSystem.get_by_code('hans').id]).order(:id).first
        FeatureNameRelation.create :parent_node_id => parent.id, :child_node_id => name.id, :is_phonetic => true, :phonetic_system_id => PhoneticSystem.get_by_code('pinyin.transcrip').id, :skip_update => true
      when 11 # Tibetan-THL Wylie
        parent = names.where(:language_id => Language.get_by_code('bod').id, :writing_system_id => WritingSystem.get_by_code('tibt').id).order(:id).first
        if parent.nil?
          FeatureNameRelation.create :parent_node_id => main_name.id, :child_node_id => name.id, :is_translation => true, :skip_update => true
        else
          FeatureNameRelation.create :parent_node_id => parent.id, :child_node_id => name.id, :is_orthographic => true, :orthographic_system_id => OrthographicSystem.get_by_code('thl.ext.wyl.translit').id, :skip_update => true
        end
      when 12 # Tibetan-THL Phonetics
        parent = names.where(:language_id => Language.get_by_code('bod').id, :writing_system_id => WritingSystem.get_by_code('tibt').id).order(:id).first
        FeatureNameRelation.create :parent_node_id => parent.id, :child_node_id => name.id, :is_phonetic => true, :phonetic_system_id => PhoneticSystem.get_by_code('thl.simple.transcrip').id, :skip_update => true
      end
    end
  end
  
  def self.kmaps_language(language_id)
    case language_id
    when 1 then Language.get_by_code('eng') # English 
    when 2, 11, 12, 17 then Language.get_by_code('bod') # Tibetan, Tibetan-THL Wylie, Tibetan-THL Phonetics, Tibetan (Amdo)
    when 3 then Language.get_by_code('dzo') # Dzongkha
    when 4 then Language.get_by_code('nep') # Nepali
    when 8, 14 then Language.get_by_code('san') # Sanskrit, Sanskrit-Transliterated
    when 9, 10, 13 then Language.get_by_code('zho') # Chinese-Traditional, Chinese-Pinyin, Chinese-Simplified
    end
  end
  
  def self.writing_system(language_id)
    case language_id
    when 1, 8, 14, 10, 11, 12 then WritingSystem.get_by_code('latin') # English, Sanskrit, Sanskrit-Transliterated, Chinese-Pinyin, Tibetan-THL Wylie, Tibetan-THL Phonetics
    when 2, 3, 17 then WritingSystem.get_by_code('tibt') # Tibetan, Dzongkha, Tibetan (Amdo)
    when 4 then WritingSystem.get_by_code('deva') # Nepali
    when 9 then WritingSystem.get_by_code('hant') # Chinese-Traditional
    when 13 then WritingSystem.get_by_code('hans') # Chinese-Simplified
    end
  end
end
