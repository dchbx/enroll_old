Then(/^the user is on the Your Preferences page$/) do
  expect(page).to have_content("Your Preferences")
end

Then(/^the answer to "([^"]*)" is defaulted to "([^"]*)"$/) do |arg1, arg2|
  find("#eligibility_easier_yes").should be_checked
end

Then(/^the field corresponding to renewal should be defaulted to (\d+) years in the data model$/) do |year|
   binding.pry
end

When(/^the user selects (\d+) years for eligibility length question$/) do |arg1|
  find(:xpath, '/html/body/div[2]/div[2]/div/form/div/div[1]/div[1]/div/div[1]/div[4]/div[2]/input').set(true)
end

Then(/^the "([^"]*)" question displays$/) do |question|
  expect(page).to have_content(question)
end

Given(/^the user selects I DISAGREE$/) do 
  find(:xpath, '//*[@id="eligibility_easier_no"]').set(true)
end
