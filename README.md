Arch:

M
-

Models represent components of an invitation/RSVP.

Production persistence mechanism is a Google Spreadsheet. This is to enable easy
editing, search, review, and phone RSVPs without having to build & secure public
endpoints for same.

A live connection to Google Spreadsheets is a pretty big external dependency,
especially for testing. Therefore, the physical persistence is abstracted out
into a "store" to be implemented against either a multi-sheet Google doc or a
directory full of CSVs. The store API is specifically spreadsheet-oriented, but
should not contain any application logic or knowledge.

On top of the selected store will be a single DAO. Since there are only four
models, it seems like an ActiveRecord-style per-model abstraction would be
overkill. The DAO will be application-aware.

IDs for models are assigned (invitiations, entree choices) or derived (guests).

V
-

Views are JSON, intended for use with Ember and so following its defaults where
reasonable. In particular, embedded instances are sideloaded. See the cucumber
features for examples.

C
-

Control is limited to the following resources:

GET /invitations/{id}
PUT /invitations/{id}

Because the IDs will need to be human-readable and typeable (and so short),
there should be some anti-brute-forcing security for both of these. Design
pending.
