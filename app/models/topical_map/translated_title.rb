# == Schema Information
#
# Table name: translated_titles
#
#  id          :integer          not null, primary key
#  title       :string(255)      not null
#  language_id :integer          not null
#  category_id :integer          not null
#  creator_id  :integer          not null
#  created_at  :datetime
#  updated_at  :datetime
#

module TopicalMap
  class TranslatedTitle < TopicalMapBase
    belongs_to :language
    belongs_to :creator, :class_name => 'User', :foreign_key => 'creator_id'
    belongs_to :category
    has_and_belongs_to_many :authors, :class_name => 'Person', :join_table => 'authors_translated_titles', :association_foreign_key => 'author_id'
  end
end