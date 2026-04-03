#import "../template.typ": sidenote

#set heading(offset: 2)
#set list(marker: [–])
#set raw(lang: "ts")

This section will document the communication between the client and the server.

#sidenote[
  For the most part, I just created these as they were needed,
  so this section is largely written retrospectively.
]

Many requests are immediately rejected if they do not come with a valid student access token or in some cases a valid teacher access token.

Also note that while IDs are stored as integers in SQLite,
SQLite integers are 64-bit, but JavaScript's main numeric type is a 64-bit float,
which cannot accurately represet all 64-bit integers.

The most efficient way to deserialize JSON in JavaScript will be to use the browser's builtin JSON parser,
`JSON.parse`, however this will automatically convert all numbers to JavaScript 64-bit floats.
Therefore IDs serialized into JSON must be serialized as strings so that no information is lost when they are deserialized.

Many of these are POST requests, in most cases this is because GET requests cannot have a body.
A QUERY method has been proposed to solve this problem, but for now POST is the best we can do.

= POST `/api/login`
Used to obtain an access token given correct login details.
/ Request: URL encoded body, with:
  / Email: The email of the account to login as
  / Password: The password used to login

  For example #raw("email=pglot%40null.ac.uk&password=pollyglot", lang: none)
/ Response:
  / Success:
    / Status: `200 OK`
    / Body: A base64 encoded access token
  / Failure:
    / Status: `401 UNAUTHORIZED`

= GET `/api/student_info`
Used to obtain basic information about the current student user.
/ Request: Requires student access token

  Note that the particular student is not part of the request,
  this simply rejects requests that aren't authenticated as a student,
  or returns information about the authenticated student.
/ Response:
  / Body: JSON encoded student information

    `object`
    - `studentId: string`
    - `schoolId: string`
    - `isDyslexic: boolean | null`
    - `forename: string`
    - `surname: string`
    - `cohorts: mapping` from `cohortId: string` to `object`
      - `tier: number`
      - `classId: string`

= GET `/api/teacher_info`
Used to obtain basic information about the current student user.
/ Request: Requires teacher access token

  Note that the particular teacher is not part of the request,
  this simply rejects requests that aren't authenticated as a teacher,
  or returns information about the authenticated teacher.
/ Response:
  / Body: JSON encoded teacher information

    `object`
    - `teacherId: string`
    - `schoolId: string`
    - `forename: string`
    - `surname: string`

= POST `/api/data/cohorts`
Used to obtain basic information about each of the requested cohorts
/ Request: Requires student access token, the student must me a member of all requested cohorts
  / Body: JSON encoded list of cohort IDs
/ Response:
  / Body: JSON encoded list of cohort information

    `array` of `object`
    - `cohortId: string`
    - `schoolId: string`
    - `name: string`
    - `tierCount: number`
    - `courses: array` of `courseId: string`

= POST `/api/data/courses`
Used to obtain basic information about each of the requested courses
/ Request: Requires student access token, the student must study each of the requested courses
  / Body: JSON encoded list of course IDs
/ Response:
  / Body: JSON encoded list of course information

    `array` of `object`
    - `courseId: string`
    - `name: string`
    - `tierCount: number`
    - `homeLanguage: string`
    - `targetLanguage: string`
    - `topics: array` of `topicId: string`

= POST `/api/data/topics`
Used to obtain basic information about each of the requested topics, up to a particular tier.
/ Request: Requires student access token, the student must study each of the requested topics
  / Body: JSON encoded

    `object`
    - `tier: number`
    - `topics: array` of `topicId: string`
/ Response:
  / Body: JSON encoded list of topic information

    `array` of `object`
    - `topicId: string`
    - `courseId: string`
    - `name: string`
    - `loadedToTier: number`
    - `words: array` of `wordId: string`

= POST `/api/data/words`
Used to obtain information of the requested words.
/ Request: Requires student access token.

  This includes checks that each word is on a course that the student studies,
  but doesn't include checks that the student's tier is high enough that they actually need to know the requested word.

  / Body: JSON encoded list of word IDs
/ Response:
  / Body: JSON encoded list of word information

    `array` of `object`
    - `wordId: string`
    - `topicId: string`
    - `headword: string`
    - `translation: number`
    - `tier: number`
    - `partOfSpeech: string | null`

= POST `/api/data/progress`
Used to obtain progress data of the requested words.
/ Request: Requires student access token.

  This doesn't perform any checks about the particular words requested.
  If there is no record of student progress for this student on this word in the database,
  default values indicated "never tested" are returned

  / Body: JSON encoded list of word IDs
/ Response:
  / Body: JSON encoded list of progress information

    `array` of `object`
    - `wordId: string`
    - `studentId: string`
    - `easeFactor: number`
    - `testInterval: number`
    - `lastTest: number | null`

= POST `/api/progress/push`
Used to send new progress data from the client to the backend.
/ Request: Requires student access token.

  This doesn't check that the words make sense for the student,
  but it does at least check that the updates are only for progress of the student whose access token was used to make the request.

  / Body: JSON encoded list of progress updates

    `array` of `object`
    - `studentId: string`
    - `wordId: string`
    - `easeFactor: number`
    - `testInterval: number`
    - `lastTest: number | null`
  / Response: `200 OK`

#sidenote[
  There's also (kinda) GET `/api/password_hash/{password}`,
  this was useful during development for hashing passwords,
  since I hadn't setup an account creation system yet.
]
