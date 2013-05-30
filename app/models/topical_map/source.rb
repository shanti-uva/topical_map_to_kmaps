# == Schema Information
#
# Table name: sources
#
#  id            :integer          not null, primary key
#  resource_id   :integer
#  resource_type :string(255)
#  mms_id        :integer
#  volume_number :integer
#  start_page    :integer
#  start_line    :integer
#  end_page      :integer
#  end_line      :integer
#  passage       :text
#  language_id   :integer          not null
#  note          :text
#  creator_id    :integer          not null
#  created_at    :datetime
#  updated_at    :datetime
#

module TopicalMap
  class Source < TopicalMapBase
    belongs_to :resource, :polymorphic => true 
    belongs_to :creator, :class_name => 'AuthenticatedSystem::User', :foreign_key => 'creator_id'
    belongs_to :language, :class_name => 'ComplexScripts::Language'
    has_many :translated_sources, :dependent => :destroy
  end
end