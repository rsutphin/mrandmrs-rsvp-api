Given /^the invitation spreadsheet$/ do |table|
  # table is a Cucumber::Ast::Table
  store.replace_sheet('Invitations', table.hashes)
end
