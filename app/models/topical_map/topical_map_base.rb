module TopicalMap
  class TopicalMapBase < ActiveRecord::Base
    self.abstract_class = true
    establish_connection(TopicalMapToKmaps.topical_map_database_yaml)
  end
end