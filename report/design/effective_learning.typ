#import "../template.typ": sidenote, warn
#import "../code_listing.typ": src-file-ref
#set heading(offset: 2)

There will be two parts to effective learning:
- The Testing Interface, which the student interacts with
- The Learning Model, which decides what to ask the student about and responds to how correctly the student answers

When I first tried to design this, I started with The Learning Model, I worked based off The Memory Chain Model @memory-chain-model.
This lead to a lot of complex maths which may or may not have been a highly accurate model.

A more applied existing model is that of SuperMemo @supermemo,
the spaced repetition software created by Piotr Wozniak (the founder of spaced repetition),
implemented in the so called _Algorithm SM-18_ @algorithm_sm-18.
That evolved from SM-2, which is the basis of the algorithms used in most spaced repetition software today @tegaru-sm-2.

According to Dominic Zijlstra of Traverse.Link though,
the actual timing of spaced repetition isn't _that_ important @optimal-spaced-repetition,
provided there is repetition, and it is spaced out in more or less the right way.

This is fortunate because perfect timing is will never be possible when most students won't be using the tool daily.

Therefore what will really make the tool effective is how well it solves these three problems:
- The External Learning Problem: Students learning vocabulary independently in class or using other tools
- The Timing Problem: Uncertainty in when the student will next use the tool and for how long
- The Engagement Problem: Uncertainty in how actively the student is engaging with the tool

The Memory Chain Model avoids these problems because they are outside the scope of the research.
SuperMemo avoids these problems by just making them the user's problem,
which seems reasonable for a software targeting highly motivated learners who want to maximise their productivity.


= The Engagement Problem: Correcting Mistakes
When a student does not get a word correct,
how can the tool ensure they have engaged with the correction?

If the tools just tells them the correct answer and moves on,
the word may only briefly enter the student's short term memory and not be retained.

The way Vocab Express handled this was quite annoying,
but probably very effective.
After being tested on each word in a particular block of words,
if you got any wrong, you would be retested on those,
then retested on the whole block again.

The bad part of this is being tested on words you already got correct once today.

== Small Mistakes
Vocab Express would give the student 1 chance to correct a slightly wrong word.
I'm being more lenient than Vocab Express.
The tool should highlight the incorrect letters and prompt the student to correct their mistake.

== Larger Mistakes
(Where the answer given by the student is completely different from the correct answer)

The Testing Interface should show the student the correct answer for as long as they need.
The student will then be prompted type out the correct answer.
When they start typing, the correct answer will be hidden again.

If the answer given by the student can be identified as a specific different word,
the tool should let the student know what question their answer would have been the answer to.

The tool should aim to test the student on this word again before the end of the session.

= The External Learning Problem
When a word is introduced, they may or may not know it already.

The Testing Interface should give the student the opportunity to show they already know that word.

The most likely scenario here is that the student just recently saw that word in class,
so the Learning Model should _not_ assume that the word will be retained long term.

= The Timing Problem
The Learning Model needs to handle the inherent uncertainty in when the student will use the tool.

It would be possible to try and analyse each student's usage patterns,
but I don't think this is practical or neccessary.

This can be solved in the Laerning Model by testing words earlier than optimal if it gets the chance.

= The Testing Interface
The interface should be as frictionless as possible.
Any frustration at all from the interface being slow or awkward to use will greatly decrease the learning potential.

To minimise interruption to the student's flow,
they should be able to do everything they need to using only their keyboard,
although for ease of use on screen buttons should be provided in most cases.

== Typing Diacritics
_This section is only really concerned with desktop devices,
since keyboards on phones and tablets usually support all major variants of each Latin character already._

Many languages use diacritics of various kinds which typical English keyboards do not provide an obvious way to write.

The Vocab Express solution to this is to leave it up to the students to figure out how to input these characters on their keyboard. This is no good.

The Linguascope solution to this is to give the student an on-screen keyboard they can interact with using their mouse which includes the other characters. This too is no good.

The tool _could_ attempt to teach students how they can input special characters on their own keyboards.
This will work in many cases.
For Spanish on a standard UK keyboard, the AltGr key which can be used to type accented vowels.
However there is no similarly easy way to type the "ñ" letter which is fairly common in Spanish,
and more important to get right than regular accents.

Luckily, there are many keys on a standard keyboard that can be repurposed into dead keys to be used in typing diacritics.

- `/a` #sym.arrow á
- `/e` #sym.arrow é
- `/i` #sym.arrow í
- `/o` #sym.arrow ó
- `/u` #sym.arrow ú
- `/n` #sym.arrow ñ
- `/A` #sym.arrow Á
- `/E` #sym.arrow É
- `/I` #sym.arrow Í
- `/O` #sym.arrow Ó
- `/U` #sym.arrow Ú
- `~N` #sym.arrow Ñ
- `-!` #sym.arrow ¡
- `-?` #sym.arrow ¿

I considered using the same character to trigger all of these replacements,
which would work reasonably well for Spanish.
However for languages with a wider range of diacritics I think there is value in keeping the
trigger keys looking like the diacritic they add where possible.

So for example a grave accent would use `\` instead of `/`.

#sidenote[
  In the final version of the code:
  - "¡" and "¿" actually use `-!` and `-?`.
  - My code made use of the Unicode Combining Diacritics.
    So most diacritics would work for _any_ Unicode character,
    not just the ones from Spanish
  - My code also supported typing diaeresis with `:`, gave accent with `\`, and tilde with `~` on letters other than "n".
]

= The Learning Model <learning-model-design>
Implemented in #src-file-ref("algorithms/learningModel.ts")

The input to the Learning Model is data from the testing interface.
Each datum consisting of:
- Which word was tested
- The test mode (reading/writing/listening)
- The "correctness". For now this is a single number

The main output to the Learning Model is deciding what words to test the student on.
It also needs to define a simple (numeric) notion "progress".

== Structure
The Learning Model has no control over when it will get the opportunity to test the student.
I therefore think it makes sense to approach the problem as looking for what word is best to test right now,
rather than when would be best to test each word.

== Testing Modes
The tool is expected to test/teach Reading, Writing, and Listening.
Speaking is also needed for many exams but testing that isn't really feasible.
Based on the interview, it sounds like Reading is considered the most important, followed by Listening, and finally Writing.

One way to handle this would be to choose which to test based on the student's confidence.
So to begin with they are only tested on Reading,
then a little later they are tested on Listening,
then finally on Writing only when they are confident with Reading and Listening.

On Vocab Express, I recall finding I wasn't necessarily able to write a word,
even if I could recognise it fairly confidently.

On Vocab Express you knew what small selection of words you would be tested on,
so you were only recognising the word from a small list of options.

This meant that if a certain word looked very different from the other words in the block,
you didn't (and in practice generally wouldn't) need to process all the letters,
so when it was time to write the word, you might be clueless.

That scenario should be a lot less common here though
because the selection of words the student could be tested on is larger.
This will hopefully mean that testing students exclusively on Reading to begin with is fine.

== Idempotence
If the model is sent the same data from the testing interface multiple times,
the effect should be the same.

Same data means same question,
same result (correctness),
and most importantly same time.

The model shouldn't be tricked into thinking the student knows a word very well just because they could correctly translate it 100 times in quick succession last year.

== SM-2
_ This is based off the description of SM-2 given by Tegaru @tegaru-sm-2 _

Like pretty much everyone else, I will base my algorithm of SM-2.

In the original form of SM-2,
the correctness
(Q --- quality of response)
is expressed as an integer from #box[0--5],
which is the student's self assessment of their understanding.

Each item in SM-2 has this state:
- Ease Factor
- Testing Interval
- Test Count

When the student is tested:
- The Easiness Factor is updated based on how correct they were
- If the quality of the response was low enough:
  - The Test Count and Testing Interval are reset
- Otherwise:
  - The Testing Interval is updated based on the Easiness Factor and the Test Count
  - The Test Count increases by 1.

The exact calculation of how the Easiness Factor changes, in terms of Q, is:
$
  Delta"EF" & = 0.1 - (5 - Q) times (0.08 + (5 - Q) times 0.02) \
            & = -0.8 + 0.28Q - 0.02Q^2
$

The testing interval is generally multiplied by the Easiness Factor,
however the first two repetitions are fixed to occur 1 day apart,
then 6 days apart.

== My Model
I will need to make some changes to the SM-2 algorithm to fit my use case.

At a minimum,
I will need to change the calculation of the Easiness Factor to use the continuous correctness instead of the discrete quality of response.

In addition to this, I will address the 4 main limitations of SM-2, as suggested by Tegaru @tegaru-sm-2:
- Fixed initial intervals
- No difficulty prediction
- Subjective Quality of Response
- No relationships between items


=== Quality of Response #sym.arrow Correctness
The obvious way to do this would be to remap the correctness (C) from a range of #box[0--1] to a range of #box[0--5]

That would be:
$ Delta"EF" = -0.8 + 1.4C - 0.5C^2 $
This seems like a reasonable starting point.

=== Initial Easiness Factor
One area that the classical SM-2 algorithm does not attempt to address is the initial value for the Easiness Factor.
This is therefore a popular part of the algorithm which other companies like to change.

The Initial Easiness Factor could just the the mean of a random sample of the words the student has seen,


