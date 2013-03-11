Feature: PUT an invitation
  In order to accept updates to an invitation
  As the application backend
  I want to accept and store invitation updates

Background:
  Given the guest spreadsheet
    | RSVP ID | Guest Name        | E-mail Address | Invited to Rehearsal Dinner? |
    | KR021   | John Fredricksson | jf@example.net | Yes                          |
    | KR021   | Emily Carolina    | ec@example.com |                              |

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
          "name": "Emily Carolina",
          "email_address": "ec@example.com",
          "attending": true,
          "entree_choice": "Cheddar-pickle sandwich"
        },
        {
          "id": "johnfredricksson",
          "attending": false,
          "name": "John Fredricksson",
          "email_address": "jf@example.net",
          "invited_to_rehearsal_dinner": true,
          "attending_rehearsal_dinner": true
        }
      ]
    }
    """
  Then the response status is 200
   And the JSON response is
    """
    { "ok": true }
    """
  Then I GET invitations/KR021
   And the JSON response is
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
          "entree_choice": null,
          "invited_to_rehearsal_dinner": true,
          "attending_rehearsal_dinner": true
        },
        {
          "id": "emilycarolina",
          "name": "Emily Carolina",
          "email_address": "ec@example.com",
          "attending": true,
          "entree_choice": "Cheddar-pickle sandwich",
          "invited_to_rehearsal_dinner": false,
          "attending_rehearsal_dinner": null
        }
      ]
    }
    """

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
          "attending": false,
          "name": "Emily Carolina",
          "email_address": "ec@example.com",
          "invited_to_rehearsal_dinner": false,
          "attending_rehearsal_dinner": null
        }
      ]
    }
    """
  Then the response status is 422
   And the JSON response is
    """
    {
      "invitation": {
        "id": "KR021",
        "errors": {
          "guests": ["cannot remove a guest"]
        }
      }
    }
    """

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
          "entree_choice": "Cheddar-pickle sandwich",
          "name": "Emily Carolina",
          "email_address": "ec@example.com"
        },
        {
          "id": "johnfredricksson",
          "attending": false,
          "name": "John Fredricksson",
          "email_address": "jf@example.net"
        },
        {
          "id": "abelincoln",
          "attending": false,
          "name": "Abe Lincoln",
          "email_address": "al@example.net"
        }
      ]
    }
    """
  Then the response status is 422
   And the JSON response is
    """
    {
      "invitation": {
        "id": "KR021",
        "errors": {
          "guests": ["cannot add a guest"]
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
          "entree_choice": null,
          "invited_to_rehearsal_dinner": true,
          "attending_rehearsal_dinner": null
        },
        {
          "id": "emilycarolina",
          "name": "Emily Carolina",
          "email_address": "ec@example.com",
          "attending": null,
          "entree_choice": null,
          "invited_to_rehearsal_dinner": false,
          "attending_rehearsal_dinner": null
        }
      ]
    }
    """

Scenario: Providing an invalid attribute value
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
          "name": "Emily Carolina",
          "email_address": "ec@example.com",
          "attending": "pickles",
          "entree_choice": "Cheddar-pickle sandwich"
        },
        {
          "id": "johnfredricksson",
          "attending": false,
          "name": "John Fredricksson",
          "email_address": "jf@example.net",
          "invited_to_rehearsal_dinner": true
        }
      ]
    }
    """
  Then the response status is 422
   And the JSON response is
    """
    {
      "guests": [
        {
          "id": "emilycarolina",
          "errors": {
            "attending": [
              "invalid value for attending"
            ]
          }
        }
      ]
    }
    """

Scenario: An invitation requested with a different case
  When I PUT the following JSON to invitations/kR021
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
          "name": "Emily Carolina",
          "email_address": "ec@example.com",
          "attending": true,
          "entree_choice": "Cheddar-pickle sandwich"
        },
        {
          "id": "johnfredricksson",
          "attending": false,
          "name": "John Fredricksson",
          "email_address": "jf@example.net",
          "invited_to_rehearsal_dinner": true
        }
      ]
    }
    """
  Then the response status is 200
   And the JSON response is
    """
    { "ok": true }
    """

Scenario: An unknown invitation
  When I PUT the following JSON to invitations/KR022
    """
    {
      "invitation": {
        "id": "KR022",
        "guests": [
          "emilycarolina"
        ]
      },

      "guests": [
        {
          "id": "emilycarolina",
          "attending": false,
          "name": "Emily Carolina",
          "email_address": "ec@example.com"
        }
      ]
    }
    """
  Then the response status is 404
   And the JSON response is
    """
    {
      "errors": [
        "There is no invitation KR022. Invitations may not be created with this interface."
      ]
    }
    """

Scenario: A mismatch between the invitation ID in the URL and the body
  When I PUT the following JSON to invitations/KR021
    """
    {
      "invitation": {
        "id": "KR022",
        "guests": [
          "emilycarolina"
        ]
      },

      "guests": [
        {
          "id": "emilycarolina",
          "attending": false,
          "name": "Emily Carolina",
          "email_address": "ec@example.com"
        }
      ]
    }
    """
  Then the response status is 422
   And the JSON response is
    """
    {
      "errors": [
        "Updates for invitation KR022 must be sent to its resource, /invitations/KR022."
      ]
    }
    """
