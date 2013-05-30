# == Schema Information
#
# Table name: translated_sources
#
#  id          :integer          not null, primary key
#  title       :text             default(""), not null
#  language_id :integer          not null
#  source_id   :integer          not null
#  creator_id  :integer          not null
#  created_at  :datetime
#  updated_at  :datetime
#

module TopicalMap
  class TranslatedSource < TopicalMapBase
    belongs_to :language, :class_name => 'ComplexScripts::Language'
    belongs_to :creator, :class_name => 'AuthenticatedSystem::User', :foreign_key => 'creator_id'
    belongs_to :source
    has_and_belongs_to_many :authors, :class_name => 'AuthenticatedSystem::Person', :join_table => 'authors_translated_sources', :association_foreign_key => 'author_id'
  end
end