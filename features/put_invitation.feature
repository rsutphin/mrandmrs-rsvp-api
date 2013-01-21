Feature: PUT an invitation
  In order to accept updates to an invitation
  As the application backend
  I want to accept and store invitation updates

Background:
  Given the invitation spreadsheet
    | RSVP ID | Guest Name        | E-mail Address |
    | KR021   | John Fredricksson | jf@example.net |
    | KR021   | Emily Carolina    | ec@example.com |


@wip
Scenario: A valid invitation
  When I PUT the following JSON to invitations/KR021
    """
    {
      "invitation": {
        "id": "KR021",
        "guests": [
          "johnfredricksson",
          "emilycarolina"
        ],
        "response_comments": "Neat-o",
        "hotel": "Crowne Plaza"
      },

      "guests": [
        {
          "id": "emilycarolina",
          "attending": true,
          "entree_choice": "Cheddar-pickle sandwich"
        },
        {
          "id": "johnfredricksson",
          "attending": false
        }
      ]
    }
    """
  Then the response status should be 200
   And I GET invitations/KR021
  Then the JSON response is
    """
    {
      "invitation": {
        "id": "KR021",
        "guests": [
          "johnfredricksson",
          "emilycarolina"
        ],
        "response_comments": "Neat-o",
        "hotel": "Crowne Plaza"
      },

      "guests": [
        {
          "id": "johnfredricksson",
          "name": "John Fredricksson",
          "email_address": "jf@example.net",
          "attending": false,
          "entree_choice": null
        },
        {
          "id": "emilycarolina",
          "name": "Emily Carolina",
          "email_address": "ec@example.com",
          "attending": true,
          "entree_choice": "Cheddar-pickle sandwich"
        }
      ]
    }
    """

@wip
Scenario: Attempting to remove a guest
  When I PUT the following JSON to invitations/KR021
    """
    {
      "invitation": {
        "id": "KR021",
        "guests": [
          "emilycarolina"
        ],
        "response_comments": "Bad, bad, thing.",
        "hotel": "Best Western"
      },

      "guests": [
        {
          "id": "emilycarolina",
          "attending": false
        }
      ]
    }
    """
  Then the response status should be 422
   And the JSON response is
    """
    {
      "invitation": {
        "id": "KR021",
        "errors": {
          "guests": ["Guests may not be removed via this interface."]
        }
      }
    }
    """

@wip
Scenario: Attempting to add a guest
  When I PUT the following JSON to invitations/KR021
    """
    {
      "invitation": {
        "id": "KR021",
        "guests": [
          "johnfredricksson",
          "emilycarolina",
          "abelincoln"
        ],
        "response_comments": "?",
        "hotel": "International"
      },

      "guests": [
        {
          "id": "emilycarolina",
          "attending": true,
          "entree_choice": "Cheddar-pickle sandwich"
        },
        {
          "id": "johnfredricksson",
          "attending": false
        },
        {
          "id": "abelincoln",
          "attending": false
        }
      ]
    }
    """
  Then the response status should be 422
   And the JSON response is
    """
    {
      "invitation": {
        "id": "KR021",
        "errors": {
          "guests": ["Guests may not be added via this interface."]
        }
      }
    }
    """
   And I GET invitations/KR021
  Then the JSON response is
    """
    {
      "invitation": {
        "id": "KR021",
        "guests": [
          "johnfredricksson",
          "emilycarolina"
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
          "entree_choice": null
        },
        {
          "id": "emilycarolina",
          "name": "Emily Carolina",
          "email_address": "ec@example.com",
          "attending": null,
          "entree_choice": null
        }
      ]
    }
    """
