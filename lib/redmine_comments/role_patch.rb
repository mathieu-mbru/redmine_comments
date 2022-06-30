require_dependency 'role'

class Role
	has_many :journal_roles, dependent: :destroy
end
