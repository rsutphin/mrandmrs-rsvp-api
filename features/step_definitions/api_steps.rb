When /^I GET (.+)$/ do |application_relative_url|
  http.get application_relative_url
end

When /^I PUT the following JSON to (.+)$/ do |application_relative_url, content|
  http.put application_relative_url, content, 'CONTENT_TYPE' => 'application/json'
end

Then /^the JSON response is$/ do |string|
  http.response.headers['content-type'].should =~ %r{^application/json}
  JSON.parse(http.response.body).should == JSON.parse(string)
end

Then /^the response status should be (\d+)$/ do |status_code|
  http.response.status.should == status_code.to_i
end
