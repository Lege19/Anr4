import type { JSX } from "solid-js/h/jsx-runtime";

/**
 * Removes an accent from a character.
 * Only supports the accents used in Spanish, for individual lowercase characters.
 * Only supports the canonical representation of the character, no combining diacritics
 * @param char - A string to remove an accent from
 * @returns The input without the accent, or undefined
 */
function removeAccent(char: string): string | undefined {
  return {
    á: "a",
    é: "e",
    í: "i",
    ó: "o",
    ú: "u",
    ü: "u",
    ñ: "n",
  }[char];
}

type SourceMap = { characters: number[]; end: number };
/**
 * A quick lookup table to get the keys that are adjacent to a certain other key on a standard QWERTY keyboard.
 */
const ADJACENT_KEYS: Record<string, string> = {
  a: "szq",
  b: "vngh",
  c: "xvdf",
  d: "sfxce",
  e: "wrd",
  f: "dgcvr",
  g: "fhvbt",
  h: "gjbny",
  i: "uok",
  j: "hknmu",
  k: "jlmi",
  l: "ko",
  m: "njk",
  n: "bmhj",
  o: "ipl",
  p: "o",
  q: "wa",
  r: "etf",
  s: "adzxw",
  t: "ryg",
  u: "yij",
  v: "cbfg",
  w: "qes",
  x: "zcsd",
  y: "tuh",
  z: "xas",
  " ": "",
};

/**
 * TypeScript has many ways to write enums.
 * This is one of those.
 *
 * Values of type `MistakeType` are `"s"`, `"i", `"d"`, and `"t"`,
 * but these can be refered to more readably as `MistakeType.Subsitution` etc
 */
export const MistakeType = {
  Substitution: "s",
  Insertion: "i",
  Deletion: "d",
  Transposition: "t",
} as const;

export type MistakeType = (typeof MistakeType)[keyof typeof MistakeType];

export type Mistake = {
  type: MistakeType;
  /**
   * The character span in the student's original (not normalised) answer where the mistake is relevant.
   *
   * The first number is the index of the first effected character
   * The second number is the index after the last effected character
   *
   * For mistakes that occur between two characters (deletion),
   * the two numbers will be the same.
   */
  span: [number, number];
};

/**
 * Bundles computation related to calculating the correctness of a student's answer.
 *
 * To reduce my own confusion, goal refers to the correct answer and input refers to the answer given by the student.
 *
 */
export class Correctness {
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
   * The normalised goal string
   */
  private readonly normGoal: string;
  /**
   * The normalised input string
   */
  private readonly normInput: string;
  /**
   * The source map from the normalised input string to the original input string
   */
  private readonly inputSourceMap: SourceMap;

  /**
   * The sequence of edits made to the goal to get to the input.
   * s = substitution
   * d = deletion
   * i = insertion
   * t = transposition
   *
   * s is used both for true substitutions, and for representing no edit (substitution a character for itself)
   *
   * `undefined` if the input strings were so different that there was no point comparing them.
   */
  private readonly editSequence: string | undefined;

  /**
   * @param goal - The answer considered correct
   * @param input - The answer give by the student
   *
   * Note that this is not commutative
   */
  constructor(goal: string, input: string) {
    this.goal = goal;
    this.input = input;

    // Defensive design
    // A student could try and break the software with a really long input. They will be disappointed
    if (this.input.length / Math.max(goal.length, 1) > 10) {
      this.distance = Infinity;
      this.correctness = 0;
      this.editSequence = undefined;
      this.normGoal = "";
      this.normInput = "";
      this.inputSourceMap = { characters: [], end: 0 };
      return;
    }

    // Normalise the goal, but discard the source map (it doesn't matter)
    [this.normGoal] = Correctness.normalise(goal);
    // Normalise the input and store the source map, it will be needed elsewhere
    [this.normInput, this.inputSourceMap] = Correctness.normalise(input);

    // Calculate the distance and edit sequence,
    // since this is the whole point of this class,
    // it's reasonable to calculate it eagerly
    [this.distance, this.editSequence] = Correctness.calculateDistance(
      this.normGoal,
      this.normInput,
    );
    // convert the distance into a correctness
    const a = (2 * this.distance) / Math.max(this.normGoal.length, 1);
    this.correctness = Math.exp(-a * a);
  }
  /**
   * An Optimal String Alignment distance optimised for typo checking,
   * The cost of insertions and substitutions depends on the physical locations of the keys on a qwerty keyboard
   *
   * The first return value is the distance
   * The second value is a that can be used to reconstruct the edit sequence
   *
   * @param goal - The goal/target string
   * @param input - The received input
   * @returns A tuple of the distance and the edit sequence.
   * The edit sequence is a string consisting of some combination of s (substitution), d (deletion), i (insertion), and t (transposition),
   * from which the edit sequence used to generate the distance can be reconstructed.
   */
  private static calculateDistance(
    goal: string,
    input: string,
  ): [number, string] {
    // Optimisation for if the goal and input are identical
    if (goal === input) return [0, "s".repeat(goal.length)];

    // The distance added when a letter is deleted
    const DELETION_DISTANCE = 1.01;
    // THe distance added when two letters are swapped
    const TRANSPOSITION_COST = 1.01;

    // The working arrays for the Wagner-Fischer Algorithm.
    // Note that since these will need to include both the 0-length prefix and the full length string,
    // the length needed is actually 1 more than the full length of the goal.

    // Since these arrays are definitely homogenous and won't grow,
    // I can go a bit faster and save some memory by using
    // JavaScript's fixed length, fixed type arrays
    const mkDistancesArray = () => new Float32Array(goal.length + 1);
    // Normally these three would go into a 2d array,
    // but I think it's a bit easier to give them names
    let prev2Distances = mkDistancesArray();
    let prev1Distances = mkDistancesArray();
    let currentDistances = mkDistancesArray();

    const mkEditSequencesArray = () => Array(goal.length + 1);
    // A "parallel" array holding the edit sequences of the prefixes instead of the distances between them.
    // The elements of this array correspond directly with the elements of prefixDistances.
    let prev2EditSequences = mkEditSequencesArray();
    let prev1EditSequences = mkEditSequencesArray();
    let currentEditSequences = mkEditSequencesArray();

    // This is an iterative Algorithm
    //
    // Wikipedia does a good job of explaining the overall idea:
    // https://en.wikipedia.org/wiki/Levenshtein_distance#Iterative_with_full_matrix
    // This is extended in the next section to reduce the space complexity to O(n),
    // which is what I have done here, although it's slightly different in this case
    // because the Wikipedia article is only concerned with Levenshtein distance,
    // which lacks transposition,
    // and so only requires the result of 1 previous iteration
    //
    // At any time, prev1Distances is the result of the previous iteration
    // prev2Distances is the result of the iteration before that
    // and the result of the current iteration is written to currentDistances
    //
    // currentDistances[n] holds the distance from the first n characters of the goal to the first j characters of the input
    // where j is the iteration we are on
    //
    // After each iteration,
    // prev2Distances is no longer needed, and is moved to occupy currentDistances
    // where it will be overwritten by the next iteration
    //
    // This is very fast because JavaScript arrays are reference types,
    // so moving them around in the array is quick,
    // And the same arrays are reused, so there are very few heap allocations.

    // Initially, prev2Distances would represent the distance between a negative length substing and the goal.
    // This is clearly meaningless
    prev2Distances.fill(Infinity);

    // Initialize prev1Distances to contain the results of the first iteration
    // This is the distances between the 0 length prefix of the input and the n-length prefixes of the goal
    // So clearly all the edits are deletions
    prev1Distances[0]! = 0;
    prev1EditSequences[0]! = "";
    for (let i = 0; i < goal.length; i++) {
      prev1Distances[i + 1]! = prev1Distances[i]! + DELETION_DISTANCE;
      prev1EditSequences[i + 1]! =
        prev1EditSequences[i]! + MistakeType.Deletion;
    }

    // We then work up through 1 length prefix of the input, then 2, and so on
    for (let j = 0; j < input.length; j++) {
      // This is the distance between the j+1-length prefix of the input and the 0-length prefix of the goal.
      // So clearly all the edits are insertions
      currentDistances[0]! =
        prev1Distances[0]! + Correctness.insertionDistance(input[j]!);
      currentEditSequences[0]! = prev1EditSequences[0]! + MistakeType.Insertion;

      // For the rest of the goal though,
      for (let i = 0; i < goal.length; i++) {
        // distance reaching this point with an insertion from a previous position
        const insertion =
          prev1Distances[i + 1]! +
          Correctness.insertionDistance(input[j]!, goal[i]!, goal[i + 1]);
        // best distance found for getting to this position
        let bestDistance = insertion;
        // and the corresponding edit sequence producing that distance
        let bestEditSequence =
          prev1EditSequences[i + 1]! + MistakeType.Insertion;

        // if a transposition is possible
        if (
          i > 0 &&
          j > 0 &&
          goal[i - 1]! === input[j]! &&
          goal[i]! === input[j - 1]!
        ) {
          // the distance of the transposition
          const transposition = prev2Distances[i - 1]! + TRANSPOSITION_COST;
          // if that's better than the current best distance
          if (transposition < bestDistance) {
            // update the best distance and best edit sequence
            bestDistance = transposition;
            bestEditSequence =
              prev2EditSequences[i - 1]! + MistakeType.Transposition;
          }
        }

        // deletion and substitution follow similarly to insertion and transposition
        const deletion = currentDistances[i]! + DELETION_DISTANCE;
        if (deletion < bestDistance) {
          bestDistance = deletion;
          bestEditSequence = currentEditSequences[i]! + MistakeType.Deletion;
        }

        // This also handles the case of the strings matching,
        // the substitutionDistance is zero if the characters are the same
        const substitution =
          prev1Distances[i]! +
          Correctness.substitutionDistance(goal[i]!, input[j]!);
        if (substitution < bestDistance) {
          bestDistance = substitution;
          bestEditSequence = prev1EditSequences[i]! + MistakeType.Substitution;
        }

        // finally, I can write the best distance and best edit sequence into the working arrays,
        // and move on to the next iteration
        currentDistances[i + 1]! = bestDistance;
        currentEditSequences[i + 1]! = bestEditSequence;
      }
      // boring code for shuffling the prefixDistances and editSequnces arrays around
      [currentDistances, prev1Distances, prev2Distances] = [
        prev2Distances,
        currentDistances,
        prev1Distances,
      ];
      [currentEditSequences, prev1EditSequences, prev2EditSequences] = [
        prev2EditSequences,
        currentEditSequences,
        prev1EditSequences,
      ];
    }
    return [prev1Distances[goal.length]!, prev1EditSequences[goal.length]!];
  }

  /**
   * - Removes capitalization and punctuation
   * - Normalises accent forms
   *
   * @param s - the string to normalise
   * @returns A tuple of the normalised form of s, and a "source map"
   * The source map is an array of numbers, the same length as the normalised form of s.
   * Each number corresponds to a character in the normalised form of s and is an index into the original s where that character originated from.
   */
  private static normalise(s: string): [string, SourceMap] {
    // convert s to lowercase
    s = s.toLowerCase();

    // split s into segments
    const segmenter = new Intl.Segmenter();
    const segments = segmenter.segment(s);

    const sourceMap = [];
    // points to the position in the student's input which is after the end of the significant part of their answer.
    let endIdx = 0;
    s = "";

    for (const segment of segments) {
      // this should be a single character if a single unicode character can even represent it
      const norm = segment.segment.normalize();
      let included = false;
      for (const c of norm) {
        // if c is not a letter, diacritic mark, or whitespace
        // (then it is some weird character I don't want to deal with and should discard)
        if (
          c.match(
            /[^\p{General_Category=Letter}\p{General_Category=Mark}\p{White_Space}]/u,
          )
        )
          continue;
        s += c;
        sourceMap.push(segment.index);
        included = true;
      }
      // if at least one character from the normalisation of this segment was included
      // and there is at least one non-whitespace charater in this segment
      if (included && norm.match(/[^\p{White_Space}]/u))
        // set the end index to be the end of this segment
        endIdx = segment.index + segment.segment.length;
    }

    // defer to a separate function to perform the extra step of collapsing consecutive whitespace characters together
    return Correctness.normaliseWhitespace([
      s,
      { characters: sourceMap, end: endIdx },
    ]);
  }
  private static normaliseWhitespace([
    s,
    { characters: sourceMap, end: endIdx },
  ]: [string, SourceMap]): [string, SourceMap] {
    // make sure the source map is the right length for the input string
    console.assert(s.length === sourceMap.length);

    // this function will work by dropping any whitespace character that had a whitespace character before it,
    // and replacing all other whitespace characters with spaces (for consistency)

    // so it makes sense to initialise this to true,
    // so that whitespace at the start of the string is removed
    let prevWhitespace = true;
    let outS = "";
    const outSourceMap = [];
    for (let idx = 0; idx < s.length; idx++) {
      const c = s[idx]!;
      const isWhitespace = Boolean(c.match(/\p{White_Space}/u));
      if (isWhitespace) {
        if (!prevWhitespace) {
          outS += " ";
          outSourceMap.push(sourceMap[idx]!);
        }
      } else {
        outS += c;
        outSourceMap.push(sourceMap[idx]!);
      }
      prevWhitespace = isWhitespace;
    }
    // remove trailing whitespace, if there is any
    if (outS[outS.length - 1] === " ") {
      outS = outS.slice(0, outS.length - 1);
      outSourceMap.pop();
    }
    return [outS, { characters: outSourceMap, end: endIdx }];
  }

  /**
   * Calculates the distance of substituting a for b,
   * taking into account accents, adjacent keys, etc.
   *
   * Returns 0 if a === b
   *
   * @param a - The expected character
   * @param b - The received character
   * @returns The distance between these two characters
   */
  private static substitutionDistance(a: string, b: string): number {
    // cost (distance) to return if b is just a but missing an accent of some kind
    const MISSED_ACCENT_COST = 0.5;
    // cost (distance) to return if a and b are adjacent on a QWERTY keyboard
    const ADJACENT_SUBSTITUTION_COST = 1.01;
    // cost (distance) to return if a and b are just different characters with no relation whatsoever
    const SUBSTITUTION_COST = 2.01;
    // if a and b are equal, the cost is zero,
    // there hasn't really been a substitution at all
    if (a === b) return 0;
    // if removing an accent from a results in b...
    if (removeAccent(a) === b) return MISSED_ACCENT_COST;
    // if a is one of the keys adjacent to b...
    if (ADJACENT_KEYS[b]?.includes(a)) return ADJACENT_SUBSTITUTION_COST;

    return SUBSTITUTION_COST;
  }
  /**
   * Calculates the distance of inserting a between b and c
   * @param a - The character being inserted
   * @param b - Optional, the character a is inserted after
   * @param c - Optional, the character a is inserted before
   * @returns The distance of inserting a between b and c
   */
  private static insertionDistance(a: string, b?: string, c?: string): number {
    // cost (distance) to return when the inserted character was an accidental double press of a key which should only have been pressed once
    const DOUBLE_COST = 1.01;
    // cost (distance) to return when the inserted character is an adjacent key to the letter before or after it
    // (the user pressed two keys by mistake)
    const ADJACENT_INSERTION_COST = 1.01;
    // cost (distance) if neither of those were the case
    const INSERTION_COST = 2.01;

    // if the inserted character is equal to either of the characters it was inserted between,
    // then this is a doubled letter
    if (a === b || a === c) return DOUBLE_COST;
    if (
      (b !== undefined && ADJACENT_KEYS[b]?.includes(a)) ||
      (c !== undefined && ADJACENT_KEYS[c]?.includes(a))
    ) {
      return ADJACENT_INSERTION_COST;
    }
    return INSERTION_COST;
  }

  /**
   * @returns An array of numbers representing the indices into the input string which were wrong
   */
  public getMistakes(): Mistake[] | undefined {
    if (this.editSequence === undefined) return undefined;
    let inputIndex = 0;
    let goalIndex = 0;
    const mistakes: Mistake[] = [];
    for (const c of this.editSequence) {
      let span: [number, number];
      switch (c as MistakeType) {
        case MistakeType.Substitution: {
          const prevInputIndex = inputIndex;
          const prevGoalIndex = goalIndex;
          inputIndex++;
          goalIndex++;
          if (this.normInput[prevInputIndex] === this.normGoal[prevGoalIndex])
            continue;
          span = [prevInputIndex, inputIndex];
          break;
        }
        case MistakeType.Insertion: {
          span = [inputIndex, inputIndex + 1];
          inputIndex++;
          break;
        }
        case MistakeType.Deletion: {
          span = [inputIndex, inputIndex];
          goalIndex++;
          break;
        }
        case MistakeType.Transposition: {
          span = [inputIndex, inputIndex + 2];
          goalIndex += 2;
          inputIndex += 2;
          break;
        }
      }
      // apply the source map to the span
      //
      // the previosuly calculated span uses indices into `this.normInput`
      // however indices into `this.input` are required
      span = span.map(
        (idx) => this.inputSourceMap.characters[idx] ?? this.inputSourceMap.end,
      ) as typeof span;
      mistakes.push({ type: c as MistakeType, span });
    }
    // check that the input and goal have been fully traversed by this edit sequence
    console.assert(inputIndex === this.normInput.length);
    console.assert(goalIndex === this.normGoal.length);

    return mistakes;
  }

  /**
   * Used for displaying debug information (some of which is not part of the public interface)
   * in `/debug/correctness`
   */
  debugDisplay(): JSX.Element {
    return (
      <>
        Distance: {this.distance}
        <br />
        Correctness: {this.correctness}
        <br />
        Mistakes: {JSON.stringify(this.getMistakes(), undefined, 2)}
        <br />
        Edit sequence: {this.editSequence}
      </>
    );
  }
}
