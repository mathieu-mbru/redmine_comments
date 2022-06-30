require_dependency 'function'

class Function
	has_many :private_notes_groups, dependent: :destroy
end
