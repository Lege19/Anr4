#import "../template.typ": bullet-con, bullet-neutral, bullet-pro, sidenote

#set heading(offset: 1)
= Introduction
The secondary school I went to mandated the use of _Vocab Express_ for students
studying a language to learn vocabulary. This made sense because memorising
large numbers of words isn't a good use of in-class time, so it would be set as
homework. However the only way to check if students have actually done this is
by testing them on it in class, which is also not a good use of class time.
Therefore a tool that allowed teachers to quickly see that their students had
done what was requested was needed.

Vocab Express has now shut down. In the few years since, the modern foreign
languages (MFL) department hasn't found a satisfactory replacement, so I'm
making one.

I met with my GCSE Spanish teacher to discuss what features of Vocab Express
worked well and what should be improved.

In this report, the target language is the language being learned, and the home
language is the student's native language. For the client the target language is
Spanish or French, and the home language is English --- but I'm keeping this
general. KS3 is Year 7-9, KS4 is Year 10 and 11, when students study take their
GCSEs.

= Interview Transcript <interview-transcript>
Summary: @interview-summary
#include "interview transcript.typ"

= Interview Summary <interview-summary>
== Vocab Express
#bullet-neutral[
  Vocab Express required someone at the school to send a list of students and
  classes to Vocab Express for it to be used. This was one person and any
  changes had to go through them
]
#bullet-neutral[
  Vocab Express didn't have a system for setting assignments (or at least if
  there was one it was never used). They set homework on a different platform
  and setting homework in two places would be inconvenient.
]
#bullet-neutral[
  Vocab Express had several different vocab lists corresponding to different
  textbooks or course specifications.
]
#bullet-pro[
  Vocab Express had a leaderboard that encouraged some students to get
  competitive.
]
#bullet-pro[
  Vocab Express allowed teachers to see how much time students had spend
  learning vocabulary.
]
#bullet-pro[
  Vocab Express had recordings of almost all words, and images with many (around
  40% I think, but there's no way to check this now).
]
#bullet-pro[
  Vocab Express had a consistent and clear way of conveying whether a noun was
  masculine or feminine: it would show nouns alongside the correct article (or
  articles if the correct article depended on context) and also show the
  plurality and gender of the word in brackets. The client really likes it this
  way, particularly the articles.
]

#bullet-pro[
  Vocab Express tested students on translating each word from the home language
  to the target language and
  from the target language to the home language, as
  well as testing students on recognising the word from a recording. These three
  modes were tested and graded separately.
]
#bullet-con[
  Vocab Express divided words into semi-arbitrary blocks of 5 to 10 words. In
  order to be considered to have learnt a particular block the student had to
  correctly translate all the words in that block in a row, getting a single one
  wrong effectively reset your progress.
]
#bullet-con[
  Vocab Express often enforced a single translation where there were multiple
  equally accurate translations for a particular word or phrase, which was very
  annoying for students.
]
#bullet-con[
  Vocab Express gave little leniency on spelling, even in English. This was
  particularly bad for dyslexic students.
]
#bullet-con[
  Vocab Express made it very easy to cheat by because you knew what words you
  were going to be tested on --- although the client thinks this wasn't such a
  problem because students would still learn _some_ vocabulary this way.
]
== Word Lists
Vocab Express had completely separate word lists between KS3 and KS4. Even
within those there would be different lists from different textbooks (and in
KS4, the list given in the GCSE course sepcification). This means that
a students progress on Vocab Express was completely reset when they started
studying at GCSE level, and potentially reset a few times before then. This does
not bother the client.

The copyright status of these is unclear as I am not a copyright lawyer. From my
research it looks like translations of individual words or phrases cannot be
copyrighted, and nor can unordered lists of words. Common sense would certainly
suggest that these lists cannot be copyrighted, but I don't want to risk it, and
large organisations tend to ignore what can and can't be copyrighted anyway by
having an army of lawyers. I will be using the AQA GCSE Spanish vocab list for
testing, but the tool should allow a school to set an arbitrary list of words.

Flexible support for vocab lists is very important because at GCSE level there is
a separate vocab list for Foundation Tier and Higher Tier, so the tool must even
support students within the same class learning from different vocab lists.

== Format
Testing students on translating words in the home language to and from the
target language is good, this should definitely be kept, but these different
modes don't need to be as separated as they were on Vocab Express. Recordings of
words are also very important, but the client thinks that text-to-speech is good
enough these days that doing actual recordings is not necessary. When testing
students on with audio, the student should be able to listen to the word as many
times as they need and even listen to it slowed down.

Vocab Express had images for most of the words. This is very helpful for some
students, so the tool should be capable of displaying images --- but how the
images are sourced is not my problem.

Vocab Express had images for most of the words. This is very helpful for some
students and should be kept.

== Spelling
The tool should allow a school to mark some students as dyslexic and be more
lenient on spelling for those students. But even in other cases the solution
should be very lenient on spelling, with the approach of asking the question
"could the student have intended to type the correct answer?", instead of "is
this sufficient to prove the student intended to type the correct answer?"

== Assignments
Setting assignments through the tool would have been useful, except that then
the teachers must set the assignment in two different places. So it is more
important that teachers have access detailed information on how much time
students have spent using the tool, what they have been learning, and the
progress they've made. And this information must be presented in an efficient
way that the teacher can easily make use of.

== Grouping Students
Students may be grouped by:
- Dyslexic or not
- Foundation Tier or Higher Tier
- "Subclass": In KS3 the MFL classes are not in sets, so if the tool were to
  support setting assignments then it should also allow the teacher to divide
  the class into pre-defined groups and set different homework for different
  groups.

== Tracking Progress
Students should get a graph of their progress through the course over time,
optionally with the date of the exam marked.

= Use Scenarios
In KS3, the tool would mainly be used for setting homework and checking
student's progress. However in KS4, in addition to this many students will want
to use the tool for revision or for systematically memorising every word in the
whole course. This creates 3 use scenarios:
- Homework
- Revision
- Bulk Memorisation

= Existing Alternatives
Now that Vocab Express is gone, there are some major alternatives to consider.

== #link("https://www.linguascope.com/")[Linguascope]
Linguascope was already used in parallel with Vocab Express at the client's
school. Linguascope divides each supported language into multiple levels,
however these are not clearly tied to any exam board or level of study. And the
vocab learning is not very streamlined --- packaged into a variety of games many
of which are a distraction rather than a help. This makes Linguascope
appropriate in Key Stage 3, but for GCSE students it's not enough.

== #link("https://quizlet.com")[Quizlet]
Quizlet has been the closest replacement used at the client's school since Vocab
Express. Quizlet is primarily a flashcards site, with user provided content.
Quizlet also supports progress tracking and other types of testing/learning, but
in my personal experience of the site (I used it when revising for my GCSEs), the
plain flashcards mode is the only one worth using. This will work well for more
disciplined students, but definitely wont work in Key Stage 3. It's unclear
whether Quizlet has any support for teachers seeing what their students have
been up to --- the teacher side of the site is mainly focused on in-class
activities. Since Quizlet lets its users create and share sets of flashcards,
teachers can set an arbitrary list of words for students to learn.

Quizlet has text to speech builtin, but it's not ideal because it doesn't play
automatically, or let you control the speed, and it reads aloud some
punctuation. For example in Spanish, many words have masculine and feminine
forms, which is often indicated with a slash. So "Rojo/a" will be read as
"Rojo barra a", instead of "Rojo, Roja", or just "Rojo". Quizlet works but it is
clear that a solution specifically designed for language learning would be
better.

== #link("https://www.duolingo.com/")[Duolingo]
Duolingo is probably the most popular language learning platform, so much so
that some of the students will already use it. Duolingo isn't designed to be
used in conjunction with in-class teaching, and as a result it doesn't give
users nearly enough control over what they are learning to be useful to teachers
setting homework. When I've used it, it's felt too gamified and the pace has
been much too slow. This wouldn't work at all.

== #link("https://senecalearning.com/")[Seneca]
Seneca does a wide range of subjects, and I've found it useful for GCSE
sciences, English, and history, but not so much modern foreign languages. The
problem for me was that Seneca is good at teaching and testing more complex
ideas, like grammar, but it's format doesn't ensure you've actually learnt
_everything_ in a particular block --- and you don't want to miss out on some
vocabulary. Seneca does do some things really well though, it shows you your
progress on many different levels, you get a percentage for the course, each
topic, and each block.

== #link("https://www.supermemo.com")[Supermemo]
Potentially a very good software.

The biggest problem is that it costs far too much to be used by schools.
In the case of my client school,
about £42,000 per year just for KS3. So that's not happening.

For comparison, Linguascope costs £420 per year for the whole school, 1% the cost.

Generally though schools simply aren't the target audience,
Supermemo offers standalone courses that aren't designed to be paired with a classroom environment.

== Conclusion
Of these, Quizlet is easily the closest to striking the right balance between
user control and structure, but it doesn't do this very well even outside the
context of language learning. That said, Quizlet is still really good for some
things, and I think some students will prefer to use Quizlet over my tool for
memorising particularly tricky vocabulary, but Quizlet is not very good for
learning the nearly 2000 words included in the AQA GCSE Spanish course.

= Fun
I also spoke to a friend who's studying Spanish A-Level about what kind of tool
he'd want to use, aiming to establish the balance between fun and focus on
vocabulary learning. In our conversation, we compared the approaches to this of
Vocab Express, Linguascope, Seneca, and Duolingo.

Through this I realised that there are actually two kinds of fun to consider:
feedback-fun, and game-fun.

== Linguascope
Linguascope puts vocabulary learning into the context of various games ---
there will be a list of words in a particular topic that you will learn, and
a selection of small games where knowledge of the words will be helpful or
required. Interestingly, this does not imply that Linguascope has feedback-fun
too. Linguascope doesn't remember what games you've played, and the games end
when you get bored and leave to play a different game, not when you win.

== Quizlet
_This wasn't covered in our conversation but I'm including it here for
completeness --- It's fairly factual anyway_
Quizlet does not have games and provides almost no feedback --- it _does_
animate the movement of the flashcards but this doesn't really count. To be fair
to Quizlet though, since it mainly relies on the discipline of the user to test
themselves rather than taking user input to test the user, it isn't able to give
much feedback because it doesn't know what the user is doing outside interacting
with the tool.

== Duolingo
Duolingo gives constant feedback - animated characters, constant
affirmations of how well you're doing, sound effects, a map where you can
see where you are and can move further along by completing lessons, etc.

== Seneca
Seneca has a good level of feedback. It has sound effects and visual effects,
and occasional affirmations but not often enough to become irritating. It also
has some vaguely relevant GIFs that get sprinkled in, which are occasionally
amusing.

== Vocab Express
Vocab Express has a little of each kind of fun. For each block of words there
was a match-up game where you matched the Spanish words to their translations.
At the end of this game, it would tell you how long you had taken, and it was
quite fun to try and finish it as quickly as possible. As a result, I still know
that "gambas" means prawns, despite the word never being useful. Vocab Express
also had _some_ limited feedback, in that you had a point counter that went up
when you practised vocabulary. This was not implemented very well however, this
counter was only visible on the home page --- not when you were actually
practising, and there was never an indication of just how much it was increasing
by, or exactly when. Despite these flaws, having a score leaderboard meant a few
students would compete to get the highest scores, but this was always limited to
just a few students, and often they would get so far ahead of everyone else that
the rest of the class would have no interest in getting competitive.

== Conclusion
We could agree that game-fun doesn't really work, the best case is that the
student spends longer on a selection of words than is necessary, and the more
likely case is that they just want to get it over with to do something that they
will enjoy more, and then the games are just a distraction from focused vocab
learning.

The level of feedback students will want will vary hugely --- we both thought
Duolingo gave too much feedback, but if everyone thought this it would probably
have been improved by now. The tool should support common forms of feedback and
the student should be given control over which they want to use:
- Sound effects
- Progress bars
- Points counters
- Visual effects (sparkles)
- Count number of correct answers in a row

= Objectives
#include "objectives.typ"
