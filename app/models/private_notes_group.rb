class PrivateNotesGroup < ActiveRecord::Base
  belongs_to :group, class_name: "Function"
  belongs_to :function
  before_destroy :delete_groups_representing_function

  # Since it is a relation table,it is deleted when a function is deleted,
  #so we also need to remove all group_id of other functions that represents this function.
  def delete_groups_representing_function
    PrivateNotesGroup.where(group_id: self.function_id).delete_all
  end
end
