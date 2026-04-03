#import "../template.typ": sidenote

#set heading(offset: 2)

#let objectives = {
  let objectives = (
    (
      id: "store-passwords",
      body: [
        Store users passwords so that they cannot be accessed even if the database and/or server is compromised.
        #sidenote[
          This as originally stated is not very measurable.
          #quote[Store password hashes rather than encrypted passwords or plaintext passwords]
          is a better alternative.
        ]
      ],
      tier: "primary",
    ),
    (
      id: "login-with-email",
      body: [
        Allow a user (a teacher or a student) to login to the tool using their registered email and password.
      ],
      tier: "primary",
    ),
    (
      id: "test-student-on-vocab",
      body: [
        Test the student on translating words to (writing) and from (reading) the target language.
      ],
      tier: "primary",
    ),
    (
      id: "track-student-confidence",
      body: [
        Track the confidence of each student on each word,
        with enough nuance to determine when would be a good time to test the student on that word again.
      ],
      tier: "primary",
    ),
    (
      id: "optimise-retension",
      body: [
        Choose which word to test the student on next to optimise their long-term retention of the vocabulary they learn.
      ],
      tier: "primary",
    ),
    (
      id: "student-choose-topics",
      body: [
        Allow a student to chose what combination of topics they want to study vocabulary from in each session.
      ],
      tier: "primary",
    ),
    (
      id: "spelling-algorithm",
      body: [
        Measure spelling accuracy with more nuance than just correct or not correct.
        This should take into account the main ways people make typos:
        - Missed keys
        - Doubled keys
        - Pressing an adjacent key instead
        - Pressing an adjacent key in addition to the intended key
        - Letter swaps
        - Missing accents

        So Levenshtein distance will not suffice.

        The algorithm is not required to consider the possibility of these being combined,
        e.g. accidentally pressing a key 3 times,
        or pressing 3 keys at once are unlikely.
      ],
      tier: "primary",
    ),
    (
      id: "organise-school",
      body: [
        Organise a school as a collection of cohorts each working on a selection of courses.
        Each cohort is divided into classes.
        Each student of a particular school can be in zero or more cohorts.
        For each cohort a student is in, they are in exactly one of the classes of that cohort.

        A class may be associated with multiple teachers,
        and each teacher can teach multiple classes.
      ],
      tier: "primary",
    ),
    (
      id: "tiers",
      body: [
        For GCSE courses, the tool must allow students in a cohort to be divided into foundation and higher tiers.

        Each word has a minimum tier,
        students on a lower tier than that do not need to know that word and must not be tested on it.
      ],
      tier: "primary",
    ),
    (
      id: "lenient-for-dyslexia",
      body: [
        Be more lenient in checking spelling for dyslexic students.
        This is to compensate for it being harder for them to spot typos as they write,
        leading to more minor inaccuracies even when they do know how to spell a word.
      ],
      tier: "primary",
    ),
    (
      id: "change-password",
      body: [
        Allow a user to change their password using a reset email or using the old password.
      ],
      tier: "secondary",
    ),
    (
      id: "teacher-mark-dyslexia",
      body: [
        Allow a teacher to mark some students as dyslexic from the teacher UI.
      ],
      tier: "secondary",
    ),
    (
      id: "consider-hesitation",
      body: [
        Consider how long the student took to type their answer in the estimation of their confidence.
      ],
      tier: "secondary",
    ),
    (
      id: "show-leaderboard",
      body: [
        Show a leaderboard of student progress in each cohort which resets every month.
      ],
      tier: "secondary",
    ),
    (
      id: "show-trajectory",
      body: [
        Show each student a graph of their progress over time.
      ],
      tier: "secondary",
    ),
    (
      id: "show-images",
      body: [
        Be able to show an image for each word
        (only when revealing or confirming the answer to a question).
        Where these images are sourced from is not my problem.
      ],
      tier: "secondary",
    ),
    (
      id: "use-text-to-speech",
      body: [
        Test a student on recognising a word when audio of the word is played using text-to-speech.
        The student is required to answer in the target language so that this is separate from knowing what the word means.
        The student should be allowed to play the audio clip as many times as they need,
        and may choose to listen to the audio clip played at 0.75x speed.

        If the student needed to slow the clip down,
        the confidence calculation should consider this an indication of lower confidence.
      ],
      tier: "secondary",
    ),
    (
      id: "teacher-can-track-students",
      body: [
        Allow a teacher to see since a particular date:
        - How much time each student has spent on a particular topic or in total
        - How much progress each student has made on a particular topic or in total
        And each student's average confidence on each topic, and over the whole course.

        This information must be able to be presented per-student,
        or collated over a class,
        or collated over all classes a teacher teaches in a particular cohort,
        or collated over all the classes in a cohort.

        This may need to be split between foundation tier and higher tier,
        since the exam board requires fewer words from foundation tier students.
        However since the topics included are generally the same,
        this may not be required.
      ],
      tier: "secondary",
    ),
    (
      id: "type-non-english-chars",
      body: [
        Provide a convient way to type characters that my not be readily availible on their usual keyboard.

        For now this will only cover Spanish characters.

        Students should be able to type these characters using only their keyboard.
        On Linguascope there were on-screen buttons to press for certain characters which was very anoying.
      ],
      tier: "tertiary",
    ),
    (
      id: "explicit-corrections",
      body: [
        Highlight specific mistakes in a student's response.

        If the correctness calculation indicates that the student likely _does_ actually know what the word is,
        the tool should give them the opportunity to correct any typos they may have made.
        It should highlight incorrect letters,
        and it should give the student the option to give up and just be shown the answer.
      ],
      tier: "tertiary",
    ),
    (
      id: "set-study-goal",
      body: [
        Allow a student to set a goal for how much progress they want to make in particular session,
        how many questions they want to answer,
        or how much time they want to spend.
        After each question they answer the tool should check if they have met their goal,
        and display a message if so.
        The message should include an option for the student to extend their goal.
      ],
      tier: "tertiary",
    ),
    (
      id: "give-hints",
      body: [
        Allow the student to ask for a hint of the first letter,
        then a second hint of the first 2 letters.

        The confidence estimation should consider if the student used this.
      ],
      tier: "tertiary",
    ),
    (
      id: "multiple-choice",
      body: [
        As an alternative to getting a hint letter,
        give the student the option to ask for a multiple choice.
      ],
      tier: "tertiary",
    ),
    (
      id: "configurable-feedback",
      body: [
        Give students control over what kinds of feedback they want to see when practising vocabulary.
        This must include whether there are sound effects,
        and whether the tool displays their progress change each time they answer a question.
        Other forms of feedback could be included,
        such as letting the student know when their position on the cohort leaderboard changes.
      ],
      tier: "tertiary",
    ),
  )
  let key-by(dicts, keyname) = dicts.map(item => (item.at(keyname), item)).to-dict()
  let group-by(dicts, keyname) = dicts.fold((:), (acc, item) => {
    let key = item.at(keyname)
    let group = acc.at(key, default: ())
    group.push(item)
    acc.insert(key, group)
    acc
  })
  (
    all: objectives,
    by-id: key-by(objectives, "id"),
    by-tier: group-by(objectives, "tier"),
  )
}

#let objective-label(id) = label("objective::" + id)
#let objective-tiers = ("primary", "secondary", "tertiary")
#let objective-numbers = {
  let objective-numbers = (:)

  let objective-number = 1

  for tier in objective-tiers {
    for objective in objectives.by-tier.at(tier) {
      objective-numbers.insert(objective.id, objective-number)
      objective-number += 1
    }
  }
  objective-numbers
}
#let objective-tier-headings = (
  primary: [Primary Objectives],
  secondary: [Secondary Objectives],
  tertiary: [Tertiary Objectives],
)

#let foreach-objective(heading-depth, table, warning) = {
  if table.keys().any(key => not key in objectives.by-id) { warn("unrecognised objective key") }

  for tier in objective-tiers {
    heading(depth: heading-depth, objective-tier-headings.at(tier))
    enum(
      tight: false,
      ..for objective in objectives.by-tier.at(tier) {
        enum.item(
          objective-numbers.at(objective.id),
          table.at(objective.id, default: warning(objective.id)),
        )
      }.children,
    )
  }
}

// for include
#foreach-objective(
  1,
  objectives
    .by-id
    .pairs()
    .map(((id, objective)) => (
      id,
      [#metadata(none)#objective-label(id)] + objective.body,
    ))
    .to-dict(),
  _ => none,
)

#let objective_quote(id) = objectives.by-id.at(id).body
#let objective_ref(id) = link(objective-label(id))[Objective~#objective-numbers.at(id)]

