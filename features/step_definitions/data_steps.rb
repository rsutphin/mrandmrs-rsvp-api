Given /^the invitation spreadsheet$/ do |table|
  # table is a Cucumber::Ast::Table
  Rails.application.store.replace_sheet(Guest.sheet_name, table.hashes)
end

Given /^the response notes spreadsheet$/ do |table|
  Rails.application.store.replace_sheet(Invitation.sheet_name, table.hashes)
end
