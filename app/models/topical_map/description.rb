# == Schema Information
#
# Table name: descriptions
#
#  id          :integer          not null, primary key
#  category_id :integer          not null
#  content     :text             default(""), not null
#  language_id :integer          not null
#  is_main     :boolean          default(FALSE), not null
#  creator_id  :integer          not null
#  created_at  :datetime
#  updated_at  :datetime
#  title       :string(255)
#

module TopicalMap
  class Description < TopicalMapBase
    belongs_to :language
    belongs_to :creator, :class_name => 'User', :foreign_key => 'creator_id'
    belongs_to :category
    has_and_belongs_to_many :authors, :class_name => 'Person', :join_table => 'authors_descriptions', :association_foreign_key => 'author_id' 
    has_many :sources, :as => :resource
  end
end