# Kelly & Rhett's Wedding: RSVP API

This application provides the back end for the RSVP page for Kelly Borden and
Rhett Sutphin's wedding. The RSVP system is a JavaScript single page app which
consumes and stores JSON from/to this API. (The front end is not in this repo.)

## Utilities

In addition to the API, this project contains a couple of ancillary utilities:

* The insert card generator (`rake insert_cards`) produces a printable PDF of
  cards containing RSVP codes to add to mailed invitations.
* The `rekey` rake task replaces the RSVP codes in the invitation spreadsheet
  with new random ones. This allows you to construct the spreadsheet using simple
  IDs and then have the production codes applied later.

## Setup

This is a Rails app; you can deploy it however you like to deploy rails apps.

In production it expects to read your invitations from a two-sheet workbook on
Google Docs named "Wedding RSVP Spreadsheet (production)". You need to set this
up by hand.

### Sheet 1: "Invitations"

Column headers (case matters): "RSVP ID", "Guest Name", "E-mail Address",
"Attending?", "Entree Choice", "Invited to Rehearsal Dinner?", "Attending
Rehearsal Dinner?".

Corresponding model: `Guest`.

* You must pre-fill "RSVP ID", "Guest Name", and (if applicable) "Invited to
  Rehearsal Dinner".
* "RSVP ID" should be be the same for all people who are invited with the same
  mailed invitation.
* Predicate columns (the ones ending with "?") have three states: "Yes", "No",
  and blank. Distinguishing blank and "No" allows for tracking where you are
  missing responses.

### Sheet 2: "Response Notes"

Column headers (case matters): "RSVP ID", "Comments", "Hotel".

Corresponding model: `Invitation` (confusing ... but the app model and the
external concepts don't quite line up and these sheet names are also part of the
UI. User needs win.)

This sheet can be left blank initially. It will be filled in / updated as PUTs
happen.

### Other sheets

You can have other sheets in the spreadsheet without affecting the API's
functioning. In mine, I have a "Stats" sheet which provides dynamically-updating
counts of RSVPs and food selections.

## Architecture

### M

Models represent components of an invitation/RSVP.

Production persistence mechanism is a Google Spreadsheet. This is to enable easy
editing, search, and review, plus entering of phone RSVPs without having to
build & secure public endpoints for same.

A live connection to Google Spreadsheets is a pretty big external dependency,
especially for testing. Therefore, the physical persistence is abstracted out
into a "store" to be implemented against either a multi-sheet Google doc or a
directory full of CSVs. The store API is specifically spreadsheet-oriented, but
should not contain any application logic or knowledge.

On top of the selected store there are be class-level DAO methods within
appropriate model classes. These are AR-like, but fitted to the needs of the
application only.

IDs for models are assigned (invitiations, entree choices) or derived (guests).

### V

Views are JSON, intended for use with Ember and so following its defaults where
reasonable. In particular, embedded instances are sideloaded. See the cucumber
features for examples.

### C

Control is limited to the following resources:

GET /invitations/{id}
PUT /invitations/{id}

Because the IDs will need to be human-readable and typeable (and so short),
there should be some anti-brute-forcing security for both of these. Design
pending.

## Google OAuth

This project uses Google OAuth's Device profile to get access to the persistence
spreadsheet. The client secret and client id need to be in
config/google_oauth.yml formatted like so:

    client_id: abcdef.apps.googleusercontent.com
    client_secret: ABC-XFT
    refresh_token: something

You can use `rake initial_device_oauth` to retrieve a refresh token. (You will
need to set client_id and client_secret to real values first.) Refresh tokens
are limited to one per client_id/user — for this app's purposes that means that
you'll need to share the refresh token between development, test, and
production.

## Reuse

Parts of this application are generic, but parts of it are not. I'm not
intending to ever make it fully generic/configurable. Please feel free to fork
and update for your situation.

Parts which you will want to change for sure if you use them:

* The `deploy` rake task
* The text in the insert card generator

Note also that the persistence model is not compatible with a high-load
environment. It is likely that if the same RSVP is updated near-simultaneously
(within the duration of a request from the server to Google), one of the updates
will be lost. If this is a problem, I recommend implementing some sort of
optimistic locking.

# License (MIT)

Copyright (c) 2013, Rhett Sutphin

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
