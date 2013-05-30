# == Schema Information
#
# Table name: categories
#
#  id         :integer          not null, primary key
#  title      :string(255)      not null
#  parent_id  :integer
#  creator_id :integer          not null
#  created_at :datetime
#  updated_at :datetime
#  published  :boolean          default(FALSE), not null
#  cumulative :boolean          default(TRUE), not null
#

module TopicalMap
  class Category < TopicalMapBase
    belongs_to :creator, :class_name => 'AuthenticatedSystem::User', :foreign_key => 'creator_id'
    #belongs_to :curator, :class_name => 'AuthenticatedSystem::Person', :foreign_key => 'curator_id'
    has_and_belongs_to_many :curators, :class_name => 'AuthenticatedSystem::Person', :join_table => 'categories_curators', :association_foreign_key => 'curator_id'
    has_many :translated_titles, :dependent => :destroy
    has_many :descriptions, :dependent => :destroy
    has_many :sources, :as => :resource 
  end
end