Feature: GET an invitation
  In order to give an attendee context for RSVPing
  As the application backend
  I want to give invitation details when given an RSVP code

Scenario: A new single-person invitation
  Given the guest spreadsheet
    | RSVP ID | Guest Name        | E-mail Address |
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
        ],
        "response_comments": null,
        "hotel": null
      },

      "guests": [
        {
          "id": "johnfredricksson",
          "name": "John Fredricksson",
          "email_address": "jf@example.net",
          "attending": null,
          "entree_choice": null,
          "invited_to_rehearsal_dinner": false,
          "attending_rehearsal_dinner": null
        }
      ]
    }
    """

Scenario: A new multiple-person invitation
  Given the guest spreadsheet
    | RSVP ID | Guest Name        | E-mail Address  |
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
        ],
        "response_comments": null,
        "hotel": null
      },

      "guests": [
        {
          "id": "giraffesutphin",
          "name": "Giraffe Sutphin",
          "email_address": "jgs@example.net",
          "attending": null,
          "entree_choice": null,
          "invited_to_rehearsal_dinner": false,
          "attending_rehearsal_dinner": null
        },
        {
          "id": "jaguarsutphin",
          "name": "Jaguar Sutphin",
          "email_address": null,
          "attending": null,
          "entree_choice": null,
          "invited_to_rehearsal_dinner": false,
          "attending_rehearsal_dinner": null
        },
        {
          "id": "elephantsutphin",
          "name": "Elephant Sutphin",
          "email_address": null,
          "attending": null,
          "entree_choice": null,
          "invited_to_rehearsal_dinner": false,
          "attending_rehearsal_dinner": null
        }
      ]
    }
    """

Scenario: An invitation which has previously been responded to
  Given the guest spreadsheet
    | RSVP ID | Guest Name        | E-mail Address | Attending? | Entree Choice |
    | KR018   | John Fredricksson | jf@example.net |            |               |
    | KR021   | Emily Carolina    | ec@example.com | y          | Veg. Lasagna  |
  And the response notes spreadsheet
    | RSVP ID | Comments             | Hotel    |
    | KR021   | Where's the pickles? | Days Inn |
  When I GET invitations/KR021
  Then the JSON response is
    """
    {
      "invitation": {
        "id": "KR021",
        "guests": [
          "emilycarolina"
        ],
        "response_comments": "Where's the pickles?",
        "hotel": "Days Inn"
      },

      "guests": [
        {
          "id": "emilycarolina",
          "name": "Emily Carolina",
          "email_address": "ec@example.com",
          "attending": true,
          "entree_choice": "Veg. Lasagna",
          "invited_to_rehearsal_dinner": false,
          "attending_rehearsal_dinner": null
        }
      ]
    }
    """

Scenario: An unknown invitation
  Given the guest spreadsheet
    | RSVP ID | Guest Name        | E-mail Address  |
    | KR018   | John Fredricksson | jf@example.net  |
    | KR021   | Emily Carolina    | ec@example.com  |
  When I GET invitations/EL010
  Then the response status is 404
   And the JSON response is
    """
    {
      "errors": [
        "There is no invitation EL010."
      ]
    }
    """

Scenario: An invitation requested with a different case
  Given the guest spreadsheet
    | RSVP ID | Guest Name        | E-mail Address  |
    | KR018   | John Fredricksson | jf@example.net  |
    | KR021   | Emily Carolina    | ec@example.com  |
  When I GET invitations/kr018
  Then the JSON response is
    """
    {
      "invitation": {
        "id": "KR018",
        "guests": [
          "johnfredricksson"
        ],
        "response_comments": null,
        "hotel": null
      },

      "guests": [
        {
          "id": "johnfredricksson",
          "name": "John Fredricksson",
          "email_address": "jf@example.net",
          "attending": null,
          "entree_choice": null,
          "invited_to_rehearsal_dinner": false,
          "attending_rehearsal_dinner": null
        }
      ]
    }
    """
