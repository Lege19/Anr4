#set heading(offset: 2)
#import "/report/template.typ": sidenote
#import "/report/analysis/objectives.typ": objective_quote, objective_ref
#import "/report/code_listing.typ": src-file-ref

This section is about achieving #objective_ref("spelling-algorithm"):

#emph(objective_quote("spelling-algorithm"))

Implemented in #src-file-ref("algorithms/correctness.tsx")

I commented that Levenshtein distance wasn't good enough,
however Levenshtein distance can be extended to Damerau-Levenshtein distance by allowing swapping adjacent letters as a primitive operation.
This is harder to calculate,
however it can be restricted to give the Optimal String Alginment Distance,
which is almost as easy to calculate as basic Levenshtein Distance.

This is pretty close to what I need,
but it doesn't take into account which letters might be easier to press accidentally.
This can be corrected by allowing the costs to depend on the surrounding characters.
Assuming a standard ISO qwerty keyboard,
the cost of insertions and substitutions should be small if the added letter is physically adjacent to the removed letter,
or one of the nearby letters.

This was surprisingly easy to implement. This prototype assumes the input to be alphabetic.
```ts
// Cost of substituting a with b
function substitutionCost(a: string, b: string): number {
  const MISSED_ACCENT_COST = 0.5;
  const ADJACENT_SUBSTITUTION_COST = 1;
  const SUBSTITUTION_COST = 2;
  if (a === b) return 0;
  if (removeAccent(a) === b) return MISSED_ACCENT_COST;
  if (ADJACENT_KEYS[b].includes(a)) return ADJACENT_SUBSTITUTION_COST;

  return SUBSTITUTION_COST;
}
// Cost of inserting a between b and c
function insertionCost(a: string, b?: string, c?: string): number {
  const DOUBLE_COST = 1;
  const ADJACENT_INSERTION_COST = 1;
  const INSERTION_COST = 2;

  if (a === b || a === c) return DOUBLE_COST;
  if (
    (b !== undefined && ADJACENT_KEYS[b].includes(a)) ||
    (c !== undefined && ADJACENT_KEYS[c].includes(a))
  ) {
    return ADJACENT_INSERTION_COST;
  }
  return INSERTION_COST;
}
// An Optimal String Alignment distance optimised for typo checking,
// The cost of insertions and substitutions depends on the physical locations of the keys on a qwerty keyboard
export function distance(goal: string, input: string): number {
  const DELETION_COST = 1;
  const TRANSPOSITION_COST = 1;

  // The working array for the Wagner-Fischer Algorithm.
  let a: number[][] = Array.from({ length: 3 }, () => Array(goal.length));

  // This is an iterative Algorithm
  //
  // Wikipedia does a good job of explaining the overall idea:
  // https://en.wikipedia.org/wiki/Levenshtein_distance#Iterative_with_full_matrix
  // This is extended in the next section to reduce the space complexity to O(n),
  // which is what I have done here, although it's slightly different in this case
  //
  // At any time, a[1] is the result of the previous iteration
  // a[0] is the result of the iteration before that
  // and the result of the current iteration is written to a[2]
  //
  // After each iteration,
  // a[0] is no longer needed, and is moved to occupy a[2]
  // where it will be ovewritten by the next iteration
  //
  // This is very fast because JavaScript arrays are reference types,
  // so moving them around in the array is quick,
  // And the same arrays are reused, so there are very few heap allocations.

  // Initialize a[1] to contain the results of the first iteration
  a[1][0] = 0;
  for (let i = 0; i < goal.length; i++) {
    a[1][i + 1] = a[1][i] + DELETION_COST;
  }

  for (let j = 0; j < input.length; j++) {
    a[2][0] = a[1][0] + insertionCost(input[j]);
    for (let i = 0; i < goal.length; i++) {
      a[2][i + 1] = Math.min(
        a[1][i] + substitutionCost(goal[i], input[j]),
        a[1][i + 1] + insertionCost(input[j], goal[i], goal[i + 1]),
        a[2][i] + DELETION_COST,
      );
      if (
        i > 1 &&
        j > 1 &&
        goal[i - 1] === input[j] &&
        goal[i] === input[j - 1]
      ) {
        a[2][i + 1] = Math.min(a[2][i + 1], a[0][i - 1] + TRANSPOSITION_COST);
      }
    }
    // Cycle a[0] to a[2]
    const a_0 = a[0];
    a = a.slice(1);
    a.push(a_0);
  }
  console.table(a);
  return a[1][goal.length];
}
```
In addition to the functions defined here,
`ADJACENT_KEYS` is a lookup table containing a list of adjacent keys for each letter of the alphabet.
`removeAccent` should return a typical ASCII representation of a lazy student not bothering to type a character with an accent properly,
or return ```ts undefined``` if the character is easy to type correctly.

This implementation follows the idea of the Wagner-Fischer algorithm,
and includes the optional optimisation to only store the portion of the working area that is actually needed.
That makes this implementation $O(n^2)$ time complexity, and $O(n)$ space complexity.

For the actual spelling algorithm, I will remove all characters that are not letters or spaces.
I'll make a slight modification to the above algorithm to also allow for spaces to be used.
This will just effect the `insertionCost` and `substitutionCost` functions.
I don't think many people will accidentally press another letter when they intended to press space,
and I think accidentally pressing space when you ment to press another letter in unlikely
This actually means that the body of those functions can stay the same,
I can just include `" "` in `ADJACENT_KEYS` and say that no keys are adjacent to space,
and space is adjacent to no keys.

= Correctness
That code calculates a _distance_, which is not very useful directly.

What would be more useful is a correctness, which is a number between 0 (not at all correct) and 1 (exactly correct).
There are a few ways this could be interpreted:
- The $p$-value in a hypothesis test where the test statistic is the student's answer,
  the null hypothesis is that they don't know the answer,
  and the alternative hypothesis is that they _do_ know the answer.
- Or, equivalently, the probability the student knows the answer, given what they wrote
- Or, a proportion of how "correct" their answer was

I've decided to use this formula,
where $c$ is correctness,
$d$ is distance,
and $l$ is the length of the correct answer:
$ c = e^(-(2 times inline(d/l))^2) $

This formula means that if there is 1 distance per character of correct answer, the correctness is approximately 0.

#sidenote[
  In the final code, this was slightly changed to handle $l = 0$.
]

= Mistakes
Since I want to highlight a student's mistakes,
it's not sufficient for the above algorithm to return just the distance,
I also need the edit sequence.

I'm not aware of any modification to this algorithm that will allow it to calculate the edit sequence without a significant performance hit.

It's possible to store the full distances array,
and then traverse this array at the end to find the edit sequence,
this keeps the time complexity $O(n m)$,
but then the space complexity is $O(n m)$, rather than $O(n)$.

It's also possible to calculate the edit sequence as you go, storing the edit sequence in the array with the distances.
This keeps the time complexity _and_ space complexity the same,
but it's clearly wasting a lot of work calculating edit sequences that get discarded later,
also, since strings in JavaScript are immutable, it performs $O(n m)$ string allocations.

I will use the latter option.

In a bit more detail, I will a second array with the same dimensions as the distances array,
which contains the edit sequence resulting in the corresponding distance.
The edit sequence is represented as a string, where each character corresponds to an edit.
- An `s` represents a substitution (or no change at all --- substituting a character for itself)
- A `d` represents a deletion --- there is a character in the answer which has no corresponding character in the student's answer
- An `i` represents an insertion --- there is a character in the student's answer which doesn't correspond to any character in the correct answer
- A `t` represents a transposition
  --- there are two characters which are one way around in the correct answer,
  but the other way around in the student's answer

For example, the edit sequence between "la pantalla" and "la apnallls" is `ssstsdsisss`.
This can then be traversed character by character to reproduce this information in a more useful format:
- `s`: substitute "l" for "l"
- `s`: substitute "a" for "a"
- `s`: substitute " ”
- `t`: transpose (swap) "pa" to "ap"
- `s`: substitute "n" for "n"
- `d`: delete "t"
- `s`: substitute "a" for "a"
- `i`: insert "l"
- `s`: substitute "l" for "l"
- `s`: substitute "l" for "l"
- `s`: substitute "a" for "s"

I will describe the algorithm for doing this, but first I need to take a detour.

== Normalisation
Certian parts of the answer are not considered important:
- Punctuation
- Leading and trailing whitespace
- Multiple whitespace characters in a row

There needs to be some process to extract from the correct answer and the student's answer the information which is considered significant which needs to match for the student's answer to be considered correct.
I call this process normailisation.

This is made more complex by the fact that unicode characters with diactritcs often have multiple equally valid representations.

For example, "á" looks the same as "á", but these are not the same in JavaScript.
The first string is 1 codepoint
(`0xe1` --- Lowercase a with accute accent)
but the second was two code points
(`0x61` --- Lowecase a --- followed by `0x0301` --- Combining accute accent)

Clearly, the student should not be penalised for missing out the accent on the a,
then penalised again for inserting an extra combining accute accent that was not expected.

What really makes this complex though, is that the mistakes are of course computed on the normalised strings, rather than the source strings.
This means that even if the spans for the mistakes are calculated correctly,
they wouldn't line up with the actual input strings for many inputs.

The solution to this is to use a source map.
This is a mapping between positions in the normalised string and positions in the source string.
The need to compute this too makes normalisation non-trivial.

The key tools needed to implement this in a robust way are the `Intl.Segmenter` JavaScript API
--- which can be used to split a string into logical characters
(more formally known as grapheme clusters),
the `String.normalize` API
--- which can be used to convert between the single character and multi-character representations of characters like "á",
and the support in RegEx for matching based on unicode character properties.

Pseudocode:
```
normalise_whitespace(s, source_map, end_index):
    previous_character_was_whitespace = True
    out_s = ""
    out_source_map = []
    for index, character in s:
        is_whitespace = character is whitespace
        if is_whitespace:
            if not previous_character_was_whitespace:
                out_s += " "
                add source_map[index] to out_source_map
        else:
            out_s += character
            add source_map[index] to out_source_map
        prev_whitespace = is_whitespace

    if last character of out_s == " ":
        remove last character from out_s
        remove last element from out_source_map
    return out_s, out_source_map, end_index

normalise(s):
    s = lowercase form of s

    segments = grapheme clusters of s
    source_map = []
    end_index = 0
    s = ""
    for segment in segments:
        norm = single character representation of segment
        included = False
        # While norm is hopefully 1 character,
        # This normalisation can fail, so this is robust against that
        for character in norm:
            if character is not a letter, combining mark, or whitespace:
                continue

            s += character
            add start index of segment to source_map
            included = True

        if included and norm is not just whitespace characters:
            end_index = end index of segment

    return normalise_whitespace(s, source_map, end_index)
```
#sidenote[
  I modified this pseudocode after I started implementing.

  I didn't anticipate the need for `endIdx`.
  Mistakes which are deletions at the end of the string require `endIdx`
  because the index of this mistake is past the end of the string and therefore wouldn't have an entry in `sourceMap`.
]

== Back to mistakes
With the source map and the edit sequence,
it's possible to calculate which parts of the student's answer need to be highlighted as mistakes. I will represent a mistake as
```ts
export type Mistake = {
  type: MistakeType;
  /**
   * Includes start
   * Does not include end
   */
  span: [number, number];
};
```
Where `MistakeType` will be one of the four characters from before (`sidt`)

To calculate the mistakes, iterate through the edit sequence and keep track of the index in the student's answer and the correct answer:
```
compute_mistakes(norm_input, norm_goal, edit_sequence, source_map, end_index):
    input_index = 0
    goal_index = 0
    mistakes = []
    for edit in edit_sequence:
        case edit of:
            "s":
                prev_input_index = input_index
                prev_goal_index = goal_index
                input_index += 1
                goal_index += 1
                if norm_input[prev_input_index] == norm_goal[prev_goal_index]:
                    continue
                span = [prev_input_index, input_index]
            "i":
                 span = [input_index, input_index + 1]
                 input_index += 1
            "d":
                 span = [input_index, input_index]
                 goal_index += 1
            "t":
                 span = [input_index, input_index + 2]
                 goal_index += 2
                 input_index += 2

        span = map positions in span:
            if position does not have an entry in source_map:
                map position to end_index
            else:
                map position to sorce_map[position]

        add { type: edit, span: span } to mistakes
    }

    return mistakes
```

= Class
This is pretty complex,
a lot of data fields and quite a few fields,
so it made sense to put this into a class.

Here's the TypeScript interface I ended up with:
```ts
interface Correctness {
  /**
   * The distance between the two strings.
   */
  public readonly distance: number;

  /**
   * The "correctness" of an answer. This is a number between zero (no similarity) and one (exactly correct).
   */
  public readonly correctness: number;

  /**
   * The original goal string
   */
  public readonly goal: string;

  /**
   * The original input string
   */
  public readonly input: string;

  /**
   * @param goal - The answer considered correct
   * @param input - The answer give by the student
   *
   * Note that this is not commutative
   */
  constructor(goal: string, input: string);

  /**
   * Compute the list of mistakes from the edit sequence
   *
   * This function may return undefined if the strings are too long to be compared,
   * this does not mean there are no mistakes.
   */
  public getMistakes(): Mistake[] | undefined;
}
```

#sidenote[
  I later added an extra public method --- `debugDisplay`
  --- which returns renderable content which includes the distance, correctness, mistakes, and edit sequence.

  This is used by a debug page `/debug/correctness`.
]
