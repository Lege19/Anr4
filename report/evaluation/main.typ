#import "../analysis/objectives.typ": foreach-objective, objective_quote
#import "../template.typ": TODO, darkgreen, darkred

#set heading(offset: 1)

#let fully-achieved = text(darkgreen)[*Fully achieved*]
#let partially-achieved = text(yellow.darken(50%))[*Partially achieved*]
#let not-achieved = text(darkred)[*Unimplemented*]

= Objectives

#foreach-objective(
  1,
  (
    store-passwords: [
      #fully-achieved

      Passwords are stored in the database as their Argon2id hashes,
      including the randomly generated salt string.

      In future, it would be good to also use peppering to make the passwords even more resistant to brute force attacks.
    ],
    login-with-email: [
      #fully-achieved

      Users can reliably log in using an email and password.

      This login page is even correctly configured for browsers to autofill passwords and emails.

      The biggest thing to improve here is staying signed in.
      Currently there is no capability to stay signed in between sessions,
      and if a session runs for longer than 15 minutes you will need to sign in again,
      as that is how long the access token is valid for.

      The way to fix this would be to add revokable single-use refresh tokens.
    ],
    track-student-confidence: [
      #partially-achieved

      I implemented this, but I'm not fully happy with the algorithm.

      I lost a lot of time trying to design the perfect algorithm for this,
      and in the end I just implemented a minor variation on the existing SM-2 algorithm.

      The best algorithm will require real world data to find,
      however even without large scale data I know this algorithm has problems.

      For example, currently the tool will never refuse to test the student on their selection of topics,
      even if there is no word that is ready to be tested.
      Ideally, the tool should tell the student that it thinks the value of more testing now would be limitted,
      and the underlying algorithm should reflect this.

      SM-2 however more or less assumes that the testing intervals were optimal,
      so if the student gets tested on a word early, it is treated the same as if they waited the optimal duration.

      This means a student could select a small topic, and go round and round testing each word multiple times in the same day,
      and trick the algorithm into thinking they have completed years worth of spaced repetition of those words.
    ],
    optimise-retension: [
      #partially-achieved

      See above
    ],
    student-choose-topics: [
      #fully-achieved

      There is a topic selector on the student home page from which the student can choose one or more topics from the selected course.
      This even features filtering by name functionality.

      When the student starts testing the words are taken from these topics only

      A possible improvement would be to allow the student to select topics from different courses,
      although I think I don't like this idea as it would be quite strange to mix multiple languages

      Another possible improvement would be to implement behaviour so that when the student filters the topics down to a single topic,
      they can press enter in the filtering box to select that topic and reset the filtering.
    ],
    teacher-can-track-students: [
      #not-achieved

      I ran out of time to implement this.

      Without these features the tool is of very limited use to the client,
      even if it could still be of use to the students themselves.

      This is the highest priority next step.
    ],
    spelling-algorithm: [
      #fully-achieved

      The spelling algorithm takes into account all the scenarios listed as described.

      Possible improvemets include:
      - Use the experimental #link("https://developer.mozilla.org/en-US/docs/Web/API/Keyboard")[Keyboard API]
        if availible to determine which keys are adjacent,
        rather than hard coding this information and assuming a QWERTY layout

      - Also accounting for extra accents

      - Returning 0 correctness more often
        --- it would seem sensible that if the two strings being compared have literally no characters in common, the correctness should always be 0,
        however currently this is not the case in the current implementation.

        Intuitively, it feels like this shouuld be measuring the similarity between what was typed and what was expected,
        which it doesn't always do a good job of.
        However I would defend this by pointing out that this is an algorithm that is always assuming the best of the user,
        i.e. that they intended to type the correct word,
        but have made one or more typos.
        Under this context, "", and "a" clearly aren't so different.

      - Extra penalty for many errors in a row.
        It's easy to miss an extra unintended character here and there,
        or to not notice that one of your keystrokes didn't register,
        however anyone would notice if several keys they press don't register,
        so typos that involve missing several keys in a row are significantly less likely.

      - Respecting word boundaries instead of whitespace.
        Currently the presence of one or more whitespace characters which are not at the beginning or end is considered significant and is checked,
        however this should really be checking word boundaries, not whitespace.
    ],
    organise-school: [
      #fully-achieved

      Despite the simplicity of this objective, there is still a bit to be improved about here.

      Currently, the tier a student is studying a course at is stored in the `CohortStudent`.

      This makes sense in some ways, for example in a GCSE cohort,
      there might be other courses --- corresponding to the textbooks they use ---
      which are separtate to the official course.
      These may often have the same foundation and higher tier distinction,
      and it makes sense that students should have the same tier for these.

      I think this is probably the best system here,
      however currently this means that the number of tiers is stored on each `Course`,
      but also on each `Cohort`.

      In the most generalised version of this,
      the number of tiers would be stored on the `Course`,
      and the tier of each student would be stored in a new link table `CourseStudent` ---
      which doesn't currently exist --- instead of the current `CohortStudent`.
    ],
    tiers: [
      #fully-achieved

      This is fully implemented,
      although focourses that don't follow the foundation/higher tier disctinction of GCSE courses the tool doesn't know the names to call the tiers by.

      Currently any course with 2 tiers are assumed to be called higher and foundation tier,
      and for courses with more tiers than that
      (I'm not aware of any such courses so this isn't a big problem),
      the courses are just refered to as the numbers.
    ],
    use-text-to-speech: [
      #not-achieved

      My intention for this was to use PiperTTS and generate the audio clips on the server when required,
      with some kind of caching to avoid generating the same audio multiple times.

      This is probably the 2nd highest prority objective that I never implemented
    ],
    type-non-english-chars: [
      #fully-achieved

      Certain characters act a bit like dead keys when used in the answer box.
      Forward slash can be used to type an accent,
      backslash can be used to type a grave accent,
      a colon can be used to type a diaeresis,
      a caret can be used to type a circumflex
      a tilde can be used to type a tilde (diacritic)
      an open parenthesis can be used to type the opening upside-down question mark and exclamation marks used in Spanish.

      This supports more characters than were required by the original objective and I'm very happy with how easy it is to type these.
    ],
    explicit-corrections: [
      #partially-achieved

      This was implemented, and I'm proud of how well it turned out, but there is room for improvement.

      For one, the current implementation will not play nice with screen readers.

      A more pressing issue is that the corrections show here directly correspond to the internal correctness algorithm.

      This
    ],
    multiple-choice: [
      #not-achieved

      This was a low priority objective which I did not have time to implement.

      If implemented it would give the student the option to request a multiple choice question if they think they would recognise the correct word but can't think of it unprompted.
    ],
    configurable-feedback: [
      #not-achieved

      This was lower priority than some other objectives because it wasn't required for the core functionality/usefulness of Anr4,
      however I think flexible configurable feedback is one of the big areas which existing tools don't do well,
      so once the core functionality is fully implemented, including most/all secondary objectives,
      then this is higher priority than the other tertiary objectives.
    ],
    set-study-goal: [
      #not-achieved

      The idea of this feature was that it was a somewhat temporary alternative to setting assignments.

      For example the teacher could set a time or progress goal on a certain topic,
      students could copy this goal across so that they could have a progress bar or similar,
      this would hopefully help students concentrate more without being distracted by checking if they've done enough yet.

      I included the space on the Student Home Page for this iterface
      --- as specified in the wireframes of my design,
      but never got round to implementing it.
    ],
    give-hints: [
      #not-achieved

      This was so low priority I don't think I even included it in my design.
      There are much more pressing issues.
    ],
    show-images: [
      #not-achieved

      In the interview, I noted that displaying images would not be hard,
      but finding the images may well be.
      I also noted that finding the images didn't need to be my problem,
      as I could just say they came from the input data.

      Implementing this was never a high priority because I would never have many images to use it with.

      The ideal way to implement this in future would probably to give users the option to submit/suggest images to be used.
    ],
    show-trajectory: [
      #not-achieved

      The current version doesn't store progress information other than the current progress on each word.

      This is largely because the main interface that would display this information
      --- that of the teachers
      --- was never implemented.

      This includes storing the progress made in each session,
      so the information this chart would represent is not availible.

      Much like some other features though,
      there is space reserved for this feature on the student home page as described in my design.

      I think for students to want to use the tool,
      there would _have_ to be at least one way for them to see how much progress they've made.
      Not neccessarily a chart, but something, and currently there isn't.

      Although this isn't important functionality for the tool to be useful,
      I don't think anyone would be willing to use it when their progress is silently recorded,
      but never reported back to them.
    ],
    show-leaderboard: [
      #not-achieved

      Unlike showing the trajectory, the information this would display actually _is_ availible.

      This was just quite a complex feature which wasn't required for anything else that I didn't get round to implementing.
    ],
    consider-hesitation: [
      #not-achieved

      Although this seems quite unimportant,
      I think it would actually be a very valuable bit of information to consider.

      This could be used to distinguish between a student getting something wrong because they aren't sure,
      and getting something wrong because they typed it very quickly.

      That said, this is a _very_ complex issue and implementing this would have taken a lot of my time that probably wouldn't have been worth the marks I may have gained.

      The reason for this complexity is that this isn't just a matter of the total time how long it took a student to answer a particular question.
      Some students will always type faster than others,
      and some students may leave the tool open for an extended period of time when they are not actively using it.
      The latter issue would also need special handling for some other features,
      as teachers don't want to know how long their students left the tool open not doing anything.

      In order to handle this well, the tool would likely need to record the time between every key stroke,
      which could then be further used in the correctness calculation.
      For example two keys with a very short time between them are much more likely to have been intended to be the other way around than if there was a significant pause between them.

      In conclusion, not implementing this was a good decision,
      and this definitely wasn't _required_ by the client,
      but it's still higher priority that some others.
    ],
    teacher-mark-dyslexia: [
      #not-achieved

      This would have been a slightly odd thing to implement given that account creation,
      including names and emails,
      was deferred to be done manually,
      as there wasn't a very clear decision from the interview on how account creation should work.

      Also, whether a student is dyslexic is only going to change when correcting previously incorrect information.

      I don't think this was high enough priority for me to even include it in the design.

      That said, once the teacher inferface is more fleshed out,
      including a mode for viewing information about an individual students.
      If this is implemented,
      whether a student is dyslexic should be shown on their info page for the teacher,
      perhaps as a switch.
      Although there should definitely be some kind of confirmation popup so teachers don't accidentally set students as dyslexic/not dyslexic when they did not intent do.
    ],
    change-password: [
      #not-achieved

      Changing a password using the old password wouldn't have been very difficult,
      as there is already code in the server to check the old password and for generating the hashes for new passwords
      --- even if the latter functionality goes largely unused.

      However, I also required that the password can be changed using a reset email,
      which is probably more important for most users.

      This of course requires sending emails from the server,
      which is very much non-trivial.

      If implemented, the server could either act as a mail server in itself,
      or it could have access to email credetials to sign into an email account on another server to send emails from their.
      The former option is probably better --- as I understand it, this would
    ],
    lenient-for-dyslexia: [
      #fully-achieved

      For dyslexic students, a correctness of 0.8 or higher is remapped to a correctness of 1.
    ],
    test-student-on-vocab: [
      #fully-achieved

      Probably the single most critical objective, if the tool couldn't do this it would be useless.
      Thankfully it can do this.
    ],
  )
    .pairs()
    .map(((id, body)) => (id, emph(objective_quote(id)) + parbreak() + body))
    .to-dict(),
  id => TODO[Evaluation for #id],
)

= Independent Feedback
This is from a friend who has previously studied GCSE Spanish:

#quote[
  I liked the correction.
  The app only accepted one translation and required the article; strangely only for spanish. However for me to become fluent in spanish, I should be allowed know other translations.
]

The correction he refers to is the live corrections where Anr4 highlights the mistakes - if there aren't many of them.

== Multiple Correct Answers
The point of only accepting one translation is a significant one,
especially as not accepting enough alternative translations was a significant problem with Vocab Express.

I think not having an objective specifically targeted at this was an oversight, but it's a bit late now.

During development,
I was aware that my original intention to use the AQA GCSE Spanish official vocab list directly had issues,
primarily that it used a variety of punctuation characters in inconsistent ways for representing variations on a translation.
I spent some time looking into fixing this problem,
and I managed to figure out when each of the punctuation characters (apart from `*`) was used
(this is not documented anywhere in the specification).

As an example --- from the official vocab list --- this is the translation of está:

(she, he, it, one) is (state, location) | (she, he, it, one) is being (state, location) | (she, he, it, one) has been (state, location) | (you (sing formal)) are (state, location) | (you (sing formal)) are being (state, location) | (you (sing formal)) have been (state, location)

To be fair to AQA, it is quite a complex word,
and I'm not claiming I could encapsulate all the ways it could be translated in any less text.

This example actually highlights an extra problem,
parenthesis are used in 3 different ways:

- Optional parts of the translation, which may be needed or omitted depending on the context

  This should _not_ have parenthesis when typed by the student

- Extra grammatical information, as in "(sing formal)"

  This _should_ have parenthesis when typed by the student

  In some cases, these are important enough that they probably should be required by the tool.

- Placeholders, as in "(state, location)"
  These are neither part of the translation nor grammatical information,
  at least not in the same way that "(sing formal)" is

  This should probably have some other way of signifying it when typed by the student,
  perhaps using square or angled brackets instead of parathensis.

  These arguably _should_ be required, as they are sufficiently important that if the

The first of these should not have parenthesis (when typed as an answer by a student),
but the latter certainly _should_ have parenthesis,
because it isn't part of the translation.

It's pretty obvious that there are a lot of options for what "está" could be translated too,
probably too many for it to be practical to list them all out and check the student's answer against all of them.

However ultimately I could see that neatly handling all these cases would be a significant development burden,
the benefit of which could not justify how long it would take and the noise it would add.
An easier solution was just to blame the data --- which I am not responsible for
--- for using all these weird characters that require non-trivial interpretation.

The result of all this is that currently at least, there is no mechanism for recognising multiple correct answers,
or even for optional parts of the translation.

== Design
There are two sides to the solution to this.
On one hand, there is the question of what the space of possible answers should actually be,
and on the other, there is the question of how that is implemented.

The AQA GCSE Spanish word list is intended to represent every possible translation a student may need to choose from,
but that's not actually what the correct answers should be.

A student that translates "está" as "(he) has been [location]" every time
clearly doesn't have a full understanding of the word.
However requiring the student to represent all possible translations of a word in their answer also isn't reasonable when there are so many.

Most students won't understand "she, he, it, one" as four options that must be remembered independently wherever they are used.
These are just the 4 English 3rd person pronouns.
So one solution might be to introduce abbreviations for these recurring features:

(3rd person | formal 2nd person) is, is being, has been [state, location]

This is short enough that I think you could reasonably require a student to write it in this way.
It could also be made even shorter by omitting the "is being",
since the Spanish present tense can always be translated in this way too.

(3rd person | formal 2nd person) is, has been [state, location]

The downside of this though is that it means students have to answer in a very particular way to be considered to know the word,
which doesn't really solve the problem.

So the best solution might be to recognise all possible translations,
but have a preferred way to translate it which the student is prompted to use instead.

As for how to implement this,
the current algorithm iteratively calculates the distance between prefixes to the correct answer.
It would be possible to allow this iteration to fork when it gets to a point with multiple options,
and it may be possible to prune branches when their distance is guaranteed to be worse than some other option.
It might also be possible to re-unite branches after they get past the part of the translation which had multiple options,
which would make the computational complexity of this fairly reasonably actually.

Given how hard this is, I suppose it's not surprising that other tools do it badly,
but that means it's an opportunity to be better than them in the future.
