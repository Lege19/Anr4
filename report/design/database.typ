#import "../template.typ": code_box, db_table
#import "/report/analysis/objectives.typ": objective_ref
#import "db_fletcher.typ": entity, erd, ghost_entity, relationship
#import "/report/code_listing.typ": src-file-ref

#set heading(offset: 2)

Implemented in #src-file-ref("initialise.sql")

To make the best design choices about the database,
it's important to establish what the most common database queries are:
- Login requests
- Updating student progress information
- Gathering data for student progress charts
- Gathering data for the leaderboard
- Deciding what word to test the student on next

In general it is good practice to use an index for any foreign key that will be queried for,
so I will be doing this.
= Logins
To meet #objective_ref("store-passwords"),
I will follow the recommendations in the OWASP password storage cheat-sheet~@owasp-password-storage-cheat-sheet.
So for each login the database will need to store the email,
password hash, and password salt.
Since some parts of the database will need to distinguish between students and teachers,
these will be stored in separate tables.
To login, the user will provide their email and password in the frontend,
and these are then sent to the server
(encrypted but not hashed).

I will defer hashing and salting passwords to the #link("https://crates.io/crates/password-auth")[RustCrypto Password Authentication] crate.
This crate actually combines the hash and the randomly generated salt into a single string,
so the database actually only needs a single column for both of these.

= Entity Relationship Diagrams
#figure(
  erd(
    spacing: (4em, 1em),
    {
      entity((-1, 0), "Login")
      entity((0, -1), "Student")
      entity((0, 1), "Teacher")
      relationship("Login", (-0.5, 0), (-0.5, -1), "Student", "1!-1?")
      relationship("Login", (-0.5, 0), (-0.5, 1), "Teacher", "1!-1?")
      entity((1, 0), "School")
      relationship("Student", (0.5, -1), (0.5, 0), "School", "n-")
      relationship("Teacher", (0.5, 1), (0.5, 0), "School", "n-")
      relationship("-n")
      entity((2, 0), "Cohort")
      relationship("-n")
      entity((3, 0), "Class")
      relationship("Student", "Cohort", corner: right, "n-n")
      relationship("Student", "Class", corner: right, "n-n")
      relationship("Teacher", "Class", corner: left, "n-n")
    },
  ),
  caption: [School Structure ERD],
)

#figure(
  erd({
    ghost_entity((1, 0), "Cohort")
    relationship("n-n")
    entity((2, 0), "Course")
    relationship("-n")
    entity((2, 1), "Topic")
    relationship("-n")
    entity((1, 1), "Word")
    relationship("n-n")
    ghost_entity((0, 1), "Student")
    relationship(corner: left, "-n")
    entity((1, 2), "Session")
    relationship("Session", "Topic", corner: left, "n-n")
  }),
  caption: [Course ERD],
)

= List of Tables
Almost everything will be #code_box(```sqlite not null```), so instead of labeling these,
I'll label the nullable columns with #code_box(```sqlite maybe null```).

#{
  let schema = read("../../migrations/20250809091053_initial.sql")
  let statements = schema.split(";").map(str.trim)
  let tables = statements.filter(statement => statement.contains("create table"))
  for table in tables {
    let match = table.match(regex(`create table ([[:word:]]+) \(((?s).*)\) strict$`.text))
    if match == none {
      panic(table)
    }
    let (name, fields) = match.captures

    fields = fields.trim()

    let rows = ()

    let trailing_primary_key = fields.match(regex(`primary key\([[:word:]]+(, [[:word:]]+)*\)`.text))
    if trailing_primary_key != none {
      fields = fields.slice(0, trailing_primary_key.start)
    }

    for field in fields.split(",").map(str.trim) {
      if field == "" {
        continue
      }
      field = field
        .replace("/*maybe null*/", "maybe null")
        .replace(" not null", "")
        .replace("integer /*boolean*/", "boolean")
      rows.push(field)
    }

    if trailing_primary_key != none {
      rows.push(trailing_primary_key.text)
    }
    [#db_table(name, ..rows)#label("db-table__" + name)]
    table.split("\n").filter(x => x.starts-with("-- ")).map(x => x.slice(3)).map(eval.with(mode: "markup")).join()
  }
}

