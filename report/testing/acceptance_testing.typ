#import "test_template.typ": failing, passing, sqlite_table, test, test_id, test_table, timestamp
#import "../template.typ": TODO, sidenote, warn
#import "../analysis/objectives.typ": foreach-objective, objective-numbers, objective_quote

#let acceptance_test(objective_id, body) = {
  emph(objective_quote(objective_id))
  test_id("A").update((objective-numbers.at(objective_id), 0))
  parbreak()
  body
}

#let test_table = test_table.with("A")

#let word(spa, eng) = [#spa/#eng]

In some tests, I will show data from the database.

Dates and durations are represented as 64-bit floating point numbers of seconds in the database,
but for the purposes of presentation they have been converted to a more readable form.

#sidenote[
  I realised a few tests in that one of my test students in the database was set as higher tier when I had intended them to be foundation tier.

  You may see a foundation tier student tested on words categorised as higher tier in the first few tests.

  These tests did not relate to the tiers system, so I have chosen not to redo them.
]

#let unimplemented = [
  I ran out of time to implement this objective. All tests would be #failing.
]

#let acceptance-tests = (
  store-passwords: [
    Polly Glot's password, as stored in the database is:

    `$argon2id$v=19$m=19456,t=2,p=1$8xNrvTr5fmRZS9EYXA9LQQ
$1d7cxdfmt3zWNy7fANx1DgWezcn2lnqjziP7zeQu3Yk`\
    (Linebreak added so it fits on the page)

    The plaintext password this was generated from was "`pollyglot`"

    This is generated using the Argon2id algorithm, and can be verified using a third party site,
    such as #link("https://argon2.online")[Argon2 Hash Generator & Verifier] (if you wish to check this yourself, make sure to remove the linebreak):
    #image(
      "media/verify_password_hash.png",
      alt: "An image showing password pollyglot verified against its hash by a third party website",
    )
  ],
  login-with-email: [
    #test_table({
      test(
        name: [Correct Student Login],
        data_category: "normal",
        input_data: [Email: pglot\@null.ac.uk\ Password: pollyglot],
        expected_result: [App continues to student home page],
        rows: (
          (kind: "run", result: [#timestamp("Correct Student Login.mp4")\ #passing]),
        ),
      )
      test(
        name: [Correct Teacher Login],
        data_category: "normal",
        input_data: [Email: nmcnully\@null.ac.uk\ Password: nullmcnully],
        expected_result: [App continues to teacher home page],
        rows: (
          (kind: "run", result: [#timestamp("Correct Teacher Login.mp4")\ #passing]),
        ),
      )
      test(
        name: [Incorrect Password],
        data_category: "normal",
        input_data: [Email: pglot\@null.ac.uk\ Password: polyglot],
        expected_result: [App informs user that email or password is incorrect, and stays on login page],
        rows: (
          (kind: "run", result: [#timestamp("Incorrect Password.mp4")\ #passing]),
        ),
      )
      test(
        name: [Incorrect Email],
        data_category: "normal",
        input_data: [Email: pglot\@gmail.com\ Password: pollyglot],
        expected_result: [
          - Stays on login page
          - Tells user that email or password is incorrect
        ],
        result: [#timestamp("Incorrect Email.mp4")\ #passing],
      )
      test(
        name: [Blank Email],
        data_category: "boundary",
        input_data: [Email: _empty_\ Password: pollyglot],
        expected_result: [
          - Stays on login page
          - Tells user to input email
        ],
        result: [#timestamp("Blank Email.mp4")\ #passing],
      )
      test(
        name: [Blank Password],
        data_category: "boundary",
        input_data: [Email: pglot\@gmail.com\ Password: _empty_],
        expected_result: [
          - Stays on login page
          - Tells user to input password _or_ that password is incorrect (either acceptable)
        ],
        result: [#timestamp("Blank Password.mp4")\ #passing],
      )
    })

  ],
  test-student-on-vocab: [
    #test_table({
      test(
        name: [Tests Reading and Writing],
        data_category: "normal",
        input_data: [Foundation tier student practicing words from Testing Topic A and Testing Topic B],
        expected_result: [The tool tests the student with both reading and writing],
        result: [#timestamp("Tests Reading and Writing.mp4")\ #passing],
      )
    })

  ],
  track-student-confidence: [
    #{
      let data = json(bytes(
        `[{"student_id":3,"word_id":10004,"ease_factor":2.129177623309892908,"test_interval":386317.9879733468988,"last_test":1768732736.183000087},
        {"student_id":3,"word_id":10000,"ease_factor":2.199999999999999289,"test_interval":399167.9999999998254,"last_test":1768732728.105999946},
        {"student_id":3,"word_id":10005,"ease_factor":2.173385926967746684,"test_interval":394339.142589027877,"last_test":1768732769.23300004},
        {"student_id":3,"word_id":10002,"ease_factor":2.199999999999999289,"test_interval":399167.9999999998254,"last_test":1768732772.095000029},
        {"student_id":3,"word_id":10003,"ease_factor":1.958249335932195523,"test_interval":343194.6297688735649,"last_test":1768732774.141999959},
        {"student_id":3,"word_id":10007,"ease_factor":2.199999999999999289,"test_interval":399167.9999999998254,"last_test":1768732781.167999983},
        {"student_id":3,"word_id":10006,"ease_factor":1.300002850748281701,"test_interval":235872.5172397682036,"last_test":1768732778.447999955},
        {"student_id":3,"word_id":10001,"ease_factor":1.843569411274526449,"test_interval":583219.1453263430158,"last_test":1768732783.41599989}]`.text,
      ))
      [This is the student progress data literally stored in the database following me intentionally getting some words wrong --- so it's not just all the same:]
      sqlite_table(data, pretty: true)
      footnote[
        In case the presentation of this data makes it untrustworthy,
        I'm getting SQLite3 to output data in JSON with ".mode json",
        and my Typst code parsing the JSON and rendering it into a nice table.
        Numbers above a certain threshold are guessed to be timestamps,
        and formatted as such.
        Numbers below this threshold but above a different one are guessed to be durations,
        and are formatted as such.
      ]
    }

    The ease factor represents how easy the student finds the word.
    If the ease factor is high,
    the testing interval will grow more rapidly than if the ease factor is low.

    The test interval can be added to the last test date to find when the word is due to be tested again.

    As you can see, word with ID 10002 (la pantalla/screen) and 10007 (la cera/wax) have the highest ease factor. I got these correct every time I was asked.
    However, word id 10001 (leer/to read) has a higher testing interval, this indicates I have not typed this word correctly every time, but have been tested more times.

  ],
  optimise-retension: [
    Scenario 1:
    #sqlite_table(
      json(bytes(
        `[{"student_id":3,"word_id":10000,"ease_factor":2.0,"test_interval":86400.0,"last_test":1768653095.0},
        {"student_id":3,"word_id":10002,"ease_factor":2.0,"test_interval":172800.0,"last_test":1768653122.0}]`.text,
      )),
      pretty: true,
    )
    Scenario 2:
    #sqlite_table(
      json(bytes(
        `[{"student_id":3,"word_id":10002,"ease_factor":2.0,"test_interval":172800.0,"last_test":1768654366.0},
        {"student_id":3,"word_id":10003,"ease_factor":2.099999999999999645,"test_interval":181439.9999999999709,"last_test":1768740801.657000065},
        {"student_id":3,"word_id":10000,"ease_factor":2.099999999999999645,"test_interval":181439.9999999999709,"last_test":1768740799.703999997}]`.text,
      )),
      pretty: true,
    )

    #test_table({
      test(
        name: [Test Word Due For Test],
        data_category: "normal",
        input_data: [Scenario 1],
        expected_result: [The student is tested on word ID 10000 (el libro/book)],
        result: [#timestamp("Test Word Due For Test.mp4")\ #passing],
      )
      test(
        name: [Introduce new word when no words are due to be tested],
        data_category: "normal",
        input_data: [Scenario 2],
        expected_result: [The student is tested on a new word],
        result: [#timestamp("Introduce New Word.mp4")\ #passing],
      )
    })

  ],
  student-choose-topics: [
    #test_table(test(
      name: [Student is tested on topics they selected],
      data_category: "normal",
      input_data: [Student selects Testing Topic A],
      expected_result: [
        Student sees only words from this topic:
        - el libro/book
        - leer/to read
        - el teclado/keyboard
        - el apodo/nickname
      ],
      result: [#timestamp("Student Choose Topics.mp4")\ #passing],
    ))

  ],
  teacher-can-track-students: [
    I ran out of time to implement the features described in this objective ---
    there was no point writing code for the teachers to track the student's use of the tool before there was much for the students to actually use.

    Instead,
    on the page where this information would otherwise be displayed,
    there's just a placeholder:
    #image("media/teacher_home_page.png", width: 40%)

    So all tests for this would be #failing.

  ],
  spelling-algorithm: [
    The main testing for this objective is in
    #link(<unit-testing-correctness>)[Unit Testing Correctness Algorithm].

    Doing acceptance testing for this directly is hard because the testing interface doesn't show the correctness or distance.
    Instead of showcasing the testing interface,
    I'll showcase `/debug/correctness`,
    which displays the output of the spelling algorithm fairly directly.

    #test_table({
      test(
        name: [Fuzzing#footnote[
            Fuzzing is a testing method where a program is fed a large quantity of random garbage nonsensical data,
            to check if it can handle this neatly.
          ] correctness],
        data_category: "erroneous",
        input_data: [
          100 random bytes (copied from `/dev/random`), interpreted as text in some way.

          Another 100 random bytes,
          which the first 100 random bytes are to be compared to.
        ],
        expected_result: [
          The spelling algorithm doesn't crash,
          the distance and correctness are not too nonsensical.

          i.e. high distance, correctness is zero or close to zero,
          many mistakes.
        ],
        rows: (
          (
            kind: "run",
            result: [
              I can't copy paste the random data into the input box.
            ],
          ),
          (
            kind: "fix",
            description: [
              I guess you can't paste binary data into FireFox.

              I did some testing using the Clipboard API,
              and FireFox doesn't even acknowledge that there is any data in my clipboard.
              (There definitely is though, because some other programs can see it)

              Instead of using pure random data, I'll use random UTF-8 from one of the many websites which provide this.
              This will still include plenty of unusual characters,
              but seems significantly less potent than data that is probably invalid.

              #image("media/correctness_fuzzing.png")
            ],
          ),
        ),
      )
    })
  ],
  tiers: [
    #test_table({
      test(
        name: [Higher and foundation tier words for higher tier student],
        data_category: "normal",
        input_data: [Higher tier student practicing Testing Topic A],
        expected_result: [
          Words that can appear are:
          - #word[el libro][book]
          - #word[leer][to read]
          - #word[el teclado][keyboard]
          - #word[el apodo][nickname]
        ],
        result: [#timestamp("Higher Tier Student Words.mp4")\ #passing],
      )
      test(
        name: [Foundation tier words only for foundation tier student],
        data_category: "normal",
        input_data: [Foundation tier student practicing Testing Topic A],
        expected_result: [
          Words that can appear are:
          - #word[el libro][book]
          - #word[el teclado][keyboard]
        ],
        rows: (
          (
            kind: "run",
            result: [
              #timestamp("Foundation Tier Student Words a (failing).mp4")
              The student gets all the same words as the higher tier student,
              including words that are higher tier, and which they therefore shouldn't be given.

              #failing
            ],
          ),
          (
            kind: "fix",
            description: [
              The `StudentHome` page was supposed to pass the tier the student should be studying the course at to the `Learn` page through the URL seach parameters, but never did.

              This was then read and defaulted to `null`, which is interpreted as "maximum tier".
            ],
          ),
          (
            kind: "run",
            result: [#timestamp("Foundation Tier Student Words b (passing).mp4")\ #passing],
          ),
        ),
      )
    })

  ],
  use-text-to-speech: unimplemented,
  type-non-english-chars: [
    The characters used in spanish that are not generally availible on standard UK keyboards are:
    áÁéÉíÍóÓúÚüÜñÑ¿¡

    áÁéÉíÍóÓúÚ are typed using `/`, for example `/a` will output á.

    üÜ are typed using `:`, for example `:u` will output ü.
    #footnote[
      Diaeresis are very occasionally used on other vowels in Spanish poetry,
      this is also supported but is unlikely to be needed
    ]

    ñÑ are typed using `~`, for example `~n` will outupt ñ.

    ¿¡ are typed using `(`, for example `(?` will output ¿.

    #test_table({
      test(
        name: [Spanish Characters],
        data_category: "normal",
        input_data: [
          `/a/A/e/E/i/I/o/O/u/U:u:U~n~N(?(!`

          (entered into the answer box)
        ],
        expected_result: [áÁéÉíÍóÓúÚüÜñÑ¿¡],
        result: [#timestamp("Spanish Characters.mp4")\ #passing],
      )
      test(
        name: [Dead Key Deletion],
        data_category: "normal",
        input_data: [
          `/<BS>a`
        ],
        expected_result: [
          \/ appears, and is deleted like a regular character.
          When `a` is typed it does not have an accent
        ],
        result: [#timestamp("Dead Key Deletion.mp4")\ #passing],
      )
      test(
        name: [Multiple Dead Keys],
        data_category: "normal",
        input_data: [
          `/:u`
        ],
        expected_result: [
          ü or \/ü
        ],
        result: [
          \/ü\
          #timestamp("Multiple Dead Keys.mp4")\
          #passing
        ],
      )
    })
  ],
  change-password: unimplemented,
  teacher-mark-dyslexia: unimplemented,
  consider-hesitation: unimplemented,
  give-hints: unimplemented,
  show-leaderboard: unimplemented,
  show-trajectory: unimplemented,
  configurable-feedback: unimplemented,
  show-images: unimplemented,
  set-study-goal: unimplemented,
  multiple-choice: unimplemented,
  explicit-corrections: [
    Since the underlying algorithms have been tested elsewhere,
    this section is focusing on the presentation of this information to the user in the live corrections interface.

    #test_table({
      test(
        name: [Highlight a mistake of each type],
        data_category: "normal",
        input_data: [
          #box["la apnallls"] instead of #box["la pantalla"]

          - Transposition: #box["pa" #sym.arrow "ap"]
          - Deletion: #box["nta" #sym.arrow "na"]
          - Insertion: #box["l" #sym.arrow "ll"]
          - Substitution: #box["la" #sym.arrow "ls"]
        ],
        expected_result: [
          The mistakes are highlighted
        ],
        rows: (
          (
            kind: "run",
            result: [
              #timestamp("Highlight a mistake of each type.mp4")\
              #passing
            ],
          ),
          (
            kind: "fix",
            description: [
              You'll notice I actually typed "la pantala" initially.

              This is because I assumed if I started with "la apnallls"
              it would be too far away from the correct word for Anr4 to enter the correction mode,
              it would just tell me it's wrong and show me the correct answer of "la pantalla".

              This assumption was actually incorrect, typing "la apnallls" was considered close enough to enter corrections,
              both on a dyslexic account and a non-dyslexic account.

              I was surprised by this and asked it what the distance and correctness had been.

              Distance: 4.04\
              Correctness: 0.583

              I checked the code for what the correctness threshold for this behaviour was and it was 0.5.
              So there isn't a bug here,
              but this has reminded me that the numbers I picked for thresholds like this one with not a lot to go on.

              I don't think entering the corrections mode when the student doesn't want it too is much of an issue though,
              as this has no effect on the learning model,
              and they can still get to the tell-me-the-answer mode by pressing enter again.
            ],
          ),
        ),
      )
      test(
        name: [Highlights placed correctly even with normalisation],
        data_category: "normal",
        input_data: [
          An answer containing many repeated, leading, and trailing whitespace characters,
          as well as plenty of unnecessary punctuation.
        ],
        expected_result: [
          The highlights stay aligned correctly
        ],
        rows: (
          (
            kind: "run",
            result: [
              #timestamp("Align mistakes a (failing).mp4")\
              #failing

              Leading spaces break the alignment
            ],
          ),
          (
            kind: "fix",
            description: [
              Based on the way this appeared, I could deduce that the mistake highlighter was losing the leading white-space,
              which was needed for the mistakes to be correctly aligned to the users input.

              This is just because the default behaviour of HTML in browsers is to treat whitespace much as my code does,
              disregarding leading and trailing whitespace, and multiple consecutive whitespace characters.

              Once this was established, it was an easy fix with a new css rule:
              ```css
              .mistake-highlighter {
                white-space: pre;
              }
              ```
            ],
          ),
          (
            kind: "run",
            result: [
              #timestamp("Align mistakes b (passing).mp4")\
              #passing
            ],
          ),
        ),
      )
    })
  ],
  lenient-for-dyslexia: [
    Data listing 1:
    #sqlite_table(
      json(bytes(
        `[{"student_id":3,"word_id":10002,"ease_factor":1.846260776594773168,"test_interval":159516.931097788416,"last_test":1770248449.842000008},
{"student_id":2,"word_id":10002,"ease_factor":1.954717137824268481,"test_interval":168887.5607080167974,"last_test":1770249322.565000057}]`.text,
      )),
      pretty: true,
    )
    #sqlite_table(
      json(bytes(
        `[{"student_id":0,"is_dyslexic":null},
{"student_id":2,"is_dyslexic":1},
{"student_id":3,"is_dyslexic":0}]`.text,
      )),
      pretty: true,
    )
    #test_table({
      test(
        name: [Dyslexic student has higher confidence estimate for same answer],
        data_category: "normal",
        input_data: [
          Case 1:\
          Dyslexic student answers with "la apnallls" for "la pantalla"

          Case 2:\
          Non-dyslexic student does the same
        ],
        expected_result: [
          When I check the database,
          I will see that the ease factor for the dyslexic student is higher than the ease factor for the non dyslexic student.
        ],
        result: [
          #timestamp("Dyslexic Student la apnallls.mp4")\
          #timestamp("Non-dyslexic Student la apnallls.mp4")\
          See data listing 1
          #passing
        ],
      )
    })
  ],
  organise-school: [
    This is entirely handled by the database schema.

    Expressed in terms of entity relationships, this is:
    - 1 school --- many cohorts
    - many cohort --- many courses
    - 1 cohort --- many classes
    - many student --- many cohorts
    - many student --- many class, but exactly 1 class per cohort

    All these constraints are enforced by the database structure.

    Each cohort belongs to exactly 1 school,
    because there is a column `school_id` of `Cohort`
    instead of a link table between `School` and `Cohort`.

    The relation between cohorts to courses is many-to-many,
    so there is a link table `CohortCourse` between these.

    Each class belongs to exactly 1 cohort,
    because there is a column `cohort_id` of `Class`
    instead of a link table between `Cohort` and `Class`.

    The relation between students and cohorts is many-to-many,
    so there is a link table `CohortStudent` between these.

    Finally, there is a column `class_id` on the _link table_ `CohortStudent`,
    which means there is exactly 1 class per student per cohort they are in.
  ],
)

#foreach-objective(
  2,
  acceptance-tests.pairs().map(((id, body)) => (id, acceptance_test(id, body))).to-dict(),
  id => warn[No acceptance test for #id],
)
