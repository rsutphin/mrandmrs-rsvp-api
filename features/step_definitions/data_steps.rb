Given /^the invitation spreadsheet$/ do |table|
  # table is a Cucumber::Ast::Table
  store.replace_sheet('Invitations', table.hashes)
end

Given /^the response notes spreadsheet$/ do |table|
  store.replace_sheet('Response Notes', table.hashes)
end
