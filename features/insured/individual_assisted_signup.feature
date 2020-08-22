Feature: Insured Plan Shopping on Individual Assisted market
  Scenario: New insured user purchases on individual market
    Given Individual has not signed up as an HBX user
    When the FAA feature configuration is enabled
    When Individual visits the Insured portal during open enrollment
    Then Aptc user create consumer role account
    Then Aptc user goes to register as individual
    Then user clicks on continue button
    Then Aptc user should see a form to enter personal information
    Then Individual agrees to the privacy agreeement
    Then user should see identity verification page and clicks on submit
    Then Individual should be on the Help Paying for Coverage page
    Then Individual does not apply for assistance and clicks continue
    Then user should see the dependents form
    And I click on continue button on household info form
    Then Prepare taxhousehold info for aptc user
    And I click on continue button on group selection page
    And Aptc user set elected amount and select plan
    Then Aptc user should see aptc amount and click on confirm button on thankyou page
    Then Aptc user should see aptc amount on receipt page
    And I click on continue button to go to the individual home page
    Then Aptc user should see aptc amount on individual home page
    Then Individual logs out
