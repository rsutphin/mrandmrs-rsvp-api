Feature: GET an invitation
  In order to give an attendee context for RSVPing
  As the application backend
  I want to give invitation details when given an RSVP code

@wip
Scenario: A new single-person invitation
  Given the invitation spreadsheet
    | RSVP ID | Guest name        | E-mail address |
    | KR018   | John Fredricksson | jf@example.net |
    | KR021   | Emily Carolina    | ec@example.com |
  When I GET invitations/KR018
  Then the JSON response is
    """
    {
      "invitation": {
        "id": "KR018",
        "guests": [
          "johnfredricksson"
        ]
      },

      "guests": [
        {
          "id": "johnfredricksson",
          "name": "John Fredricksson",
          "email_address": "jf@example.net",
          "attending": null
        }
      ]
    }
    """

@wip
Scenario: A new multiple-person invitation
  Given the invitation spreadsheet
    | RSVP ID | Guest name        | E-mail address  |
    | KR018   | John Fredricksson | jf@example.net  |
    | KR021   | Emily Carolina    | ec@example.com  |
    | EL000   | Giraffe Sutphin   | jgs@example.net |
    | EL000   | Jaguar Sutphin    |                 |
    | EL000   | Elephant Sutphin  |                 |
  When I GET invitations/EL000
  Then the JSON response is
    """
    {
      "invitation": {
        "id": "EL000",
        "guests": [
          "giraffesutphin",
          "jaguarsutphin",
          "elephantsutphin"
        ]
      },

      "attendees": [
        {
          "id": "giraffesutphin",
          "name": "Giraffe Sutphin",
          "email_address": "jgs@example.net",
          "attending": ""
        },
        {
          "id": "jaguarsutphin",
          "name": "Jaguar Sutphin",
          "email_address": null,
          "attending": null
        },
        {
          "id": "elephantsutphin",
          "name": "Elephant Sutphin",
          "email_address": null,
          "attending": null
        }
      ]
    }
    """
