require "spec_helper"

describe Journal do

  fixtures :users, :roles, :projects, :members, :member_roles, :issues, :issue_statuses,
           :trackers, :enumerations, :custom_fields, :enabled_modules,
           :journals, :journal_details

  let!(:user_jsmith) { User.find(2) }
  let!(:user_dloper) { User.find(3) }
  let!(:issue) { Issue.find(1) }
  let!(:manager) { Role.find(1) }
  let!(:developer) { Role.find(2) }
  let!(:private_note) { Journal.create(notes: "Just a private note",
                                       journalized: issue,
                                       user_id: 1,
                                       private_notes: true) }

  if Redmine::Plugin.installed?(:redmine_limited_visibility)
    let!(:contractor_role) { Function.where(name: "Contractors").first_or_create }
    let!(:project_office_role) { Function.where(name: "Project Office").first_or_create }
    let!(:function) { Function.first }
    fixtures :functions

    describe "notified users" do

      it "notify everybody when note is not private" do
        private_note.private_notes = false
        expect(private_note.notified_users.size).to eq 2
        expect(private_note.notified_users).to eq issue.notified_users
      end

      it "does not notify developers when they have no permissions" do
        developer.remove_permission!(:view_private_notes,
                                   :view_private_notes_from_role_or_function)

        expect(user_dloper.allowed_to?(:view_private_notes, issue.project)).to be_falsey
        expect(developer.allowed_to?(:view_private_notes)).to be_falsey
        expect(developer.has_permission?(:view_private_notes)).to be_falsey
        expect(private_note.private_notes).to be_truthy

        expect(private_note.notified_users).to_not include user_dloper
      end

      it "notify developers if they have standard permission" do
        developer.add_permission!(:view_private_notes)
        developer.remove_permission!(:view_private_notes_from_role_or_function)
        expect(private_note.notified_users).to include user_dloper
      end

      it "notify developers if they have new permission by role or function" do
        private_note.functions = [project_office_role]
        membership = Member.find_by(project: issue.project, user: user_dloper)
        membership.functions = [project_office_role]

        developer.remove_permission!(:view_private_notes)
        developer.add_permission!(:view_private_notes_from_role_or_function)

        expect(private_note.notified_users).to include user_dloper
        expect(private_note.notified_users).to include user_jsmith
      end

    end

    it "Update the JournalFunction table, when deleting a journal" do
      journal = Journal.first
      JournalFunction.create(journal_id: journal.id, function_id: function.id)
      expect do
        journal.destroy
      end.to change { JournalFunction.count }.by(-1)
    end

    it "Update the PrivateNotesGroup table, when deleting a function" do
      group = Function.last
      PrivateNotesGroup.create(group_id: group.id, function_id: function.id)
      PrivateNotesGroup.create(group_id: function.id, function_id: group.id)
      expect do
        function.destroy
      end.to change { PrivateNotesGroup.count }.by(-2)
    end

  end

  describe "Update the JournalRole table" do
    let!(:journal) { Journal.first }
    it "when deleting a role" do
      role_test = Role.create!(:name => 'Test')
      JournalRole.create(journal_id: journal.id, role_id: role_test.id)
      expect do
        role_test.destroy
      end.to change { JournalRole.count }.by(-1)
    end

    it "when deleting a journal" do
      role = Role.first
      JournalRole.create(journal_id: journal.id, role_id: role.id)
      expect do
        journal.destroy
      end.to change { JournalRole.count }.by(-1)
    end
  end

end
