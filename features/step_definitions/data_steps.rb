Given /^the invitation spreadsheet$/ do |table|
  # table is a Cucumber::Ast::Table
  Rails.application.store.replace_sheet(Invitation::GUESTS_SHEET_NAME, table.hashes)
end

Given /^the response notes spreadsheet$/ do |table|
  Rails.application.store.replace_sheet(Invitation::INVITATIONS_SHEET_NAME, table.hashes)
end
