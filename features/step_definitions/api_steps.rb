When /^I GET (.+)$/ do |application_relative_url|
  http.get application_relative_url
end

Then /^the JSON response is$/ do |string|
  http.response.headers['content-type'].should =~ %r{^application/json}
  JSON.parse(http.response.body).should == JSON.parse(string)
end
