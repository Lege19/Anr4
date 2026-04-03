import { Correctness, MistakeType, type Mistake } from "./correctness";
import { expect, test } from "vitest";

const TESTS: {
  name: string;
  goal: string;
  input: string;
  distance?: number;
  correctness?: number;
  mistakes?: Mistake[] | undefined;
}[] = [
  {
    name: "duplicate",
    goal: "a",
    input: "aa",
    distance: 1.01,
  },
  {
    name: "adjacent insertion",
    goal: "a",
    input: "as",
    distance: 1.01,
  },
  {
    name: "general insertion",
    goal: "a",
    input: "ag",
    distance: 2.01,
  },
  {
    name: "adjacent substitution",
    goal: "a",
    input: "s",
    distance: 1.01,
  },
  {
    name: "general substitution",
    goal: "a",
    input: "g",
    distance: 2.01,
  },
  {
    name: "missed accent",
    goal: "á",
    input: "a",
    distance: 0.5,
  },
  {
    name: "deletion",
    goal: "a",
    input: "",
    distance: 1.01,
  },
  {
    name: "transposition",
    goal: "ab",
    input: "ba",
    distance: 1.01,
  },
  {
    name: "keysmash",
    goal: "oairensb",
    input: "oienarst",
    distance:
      /* delete a */ 1.01 +
      /* delete r */ 1.01 +
      /* insert a adjacent to s */ 1.01 +
      /* insert r, not adjacent to anything */ 2.01 +
      /* replace b with t, not adjacent */ 2.01,
    mistakes: [
      { type: MistakeType.Deletion, span: [1, 1] },
      { type: MistakeType.Deletion, span: [2, 2] },
      { type: MistakeType.Insertion, span: [4, 5] },
      { type: MistakeType.Insertion, span: [5, 6] },
      { type: MistakeType.Substitution, span: [7, 8] },
    ],
  },
  {
    name: "empty strings",
    goal: "",
    input: "",
    distance: 0,
    correctness: 1,
    mistakes: [],
  },
  {
    name: "very long input",
    goal: "a".repeat(1000),
    input: "a".repeat(1000),
    distance: 0,
    correctness: 1,
  },
  {
    name: "normalisation",
    goal: "a, b!  a''",
    input: "a b. a.....",
    distance: 0,
    correctness: 1,
    mistakes: [],
  },
  {
    name: "frustrated student tries to break software with long input",
    goal: "a".repeat(100),
    input: "a".repeat(100000),
    distance: Infinity,
    correctness: 0,
  },
];
for (const {
  name,
  goal,
  input,
  distance: expectedDistance,
  correctness: expectedCorrectness,
  mistakes: expectedMistakes,
} of TESTS) {
  test("Test Correctness distance/correctness calculation: " + name, () => {
    const correctness = new Correctness(goal, input);
    if (expectedDistance)
      expect(correctness.distance).toBeCloseTo(expectedDistance);
    if (expectedCorrectness)
      expect(correctness.correctness).toBe(expectedCorrectness);
    if (expectedMistakes)
      expect(correctness.getMistakes()).toStrictEqual(expectedMistakes);
  });
}
