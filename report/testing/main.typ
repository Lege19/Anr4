#import "test_template.typ": *
#import "../code_listing.typ": src-file-ref
#set heading(offset: 1)

/ #normal-data: Normal Data
/ #boundary-data: Boundary Data
/ #erroneous-data: Erroneous Data

The URL for the testing video is #link(VIDEO-URL, VIDEO-URL).

#metadata(VIDEO-DESCRIPTION)<video-description>

= Unit Testing
Test are run using Vitest in NodeJS 22.
== Correctness Calculation <unit-testing-correctness>
Most tests don't test Correctness.
This is because the only correctness value that is really predictable is
correctness = 1 when the strings match.

These tests were only written/run after the obvious problems were fixed,
hence why most of them just work first time.
In reality it tool many iterations to get the distance code correct.

At the time of writing, the distance contributions were as follows:
- Doubled letter: 1
- Insertion of adjacent letter: 1
- Insertion of non-adjacent letter: 2
- Substitution for adjacent letter: 1
- Substitution for non-adjacent letter: 1
- Missing accent: 0.5
- Deleted character: 1
- Swap 2 characters: 1

#let test_table = test_table.with("U")

#test_id("U").step()

#test_table({
  test(
    name: [Doubled Letter],
    data_category: "normal",
    input_data: [Goal: "a"\ Input: "aa"],
    expected_result: [Distance: 1],
    rows: ((kind: "run", result: [Distance: 1\ #passing]),),
  )
  test(
    name: [Insertion of an adjacent character],
    data_category: "normal",
    input_data: [Goal: "a"\ Input: "as"],
    expected_result: [Distance: 1],
    rows: ((kind: "run", result: [Distance: 1\ #passing]),),
  )
  test(
    name: [Insertion of a non-adjacent character],
    data_category: "normal",
    input_data: [Goal: "a"\ Input: "ag"],
    expected_result: [Distance: 2],
    rows: ((kind: "run", result: [Distance: 2\ #passing]),),
  )
  test(
    name: [Substitution for an adjacent character],
    data_category: "normal",
    input_data: [Goal: "a"\ Input: "s"],
    expected_result: [Distance: 1],
    rows: ((kind: "run", result: [Distance: 1\ #passing]),),
  )
  test(
    name: [Substitution for a non-adjacent character],
    data_category: "normal",
    input_data: [Goal: "a"\ Input: "g"],
    expected_result: [Distance: 2],
    rows: ((kind: "run", result: [Distance: 2\ #passing]),),
  )
  test(
    name: [Missing accent],
    data_category: "normal",
    input_data: [Goal: "á"\ Input: "a"],
    expected_result: [Distance: 0.5],
    rows: (
      (kind: "run", result: [Distance: 0\ #failing]),
      (
        kind: "fix",
        description: [
          I previously changed the code from using a plain array of floats to a Uint16Array.
          Some other code attempted to initialise one such array to float Infinity, which was turned into 0 when converted,
          rather than 65535, as one might have hoped.

          Not to mention the fact that Uint16 cannot represent fractional distances.

          Fix: use a Float32Array instead, where float Infinity is meaningful.
        ],
      ),
      (
        kind: "run",
        result: [Distance: 0.5\ #passing],
      ),
    ),
  )

  test(
    name: [Deleted Character],
    data_category: "normal",
    input_data: [Goal: "a"\ Input: ""],
    expected_result: [Distance: 1],
    rows: ((kind: "run", result: [Distance: 1\ #passing]),),
  )
  test(
    name: [Transposition (swap 2 characters)],
    data_category: "normal",
    input_data: [Goal: "ab"\ Input: "ba"],
    expected_result: [Distance: 1],
    rows: ((kind: "run", result: [Distance: 1\ #passing]),),
  )
  test(
    name: [Random letters],
    data_category: "normal",
    input_data: [Goal: "oairensb"\ Input: "oienarst"],
    expected_result: [
      Distance:\
      #set list(marker: none)
      - $+ 1$ for deleting a
      - $+ 1$ for deleting r
      - $+ 1$ for inserting a,
        which is adjacent to s
      - $+ 2$ for inserting r
      - $+ 2$ for replacing b with t
      - $= 7$

      Mistakes:\
      - Deletion at [1, 1)
      - Deletion at [2, 2)
      - Insertion at [4, 5)
      - Insertion at [5, 6)
      - Substitution at [7, 8)
    ],
    rows: ((kind: "run", result: [Distance: 7\ #passing]),),
  )
  test(
    name: [Empty Strings],
    data_category: "boundary",
    input_data: [Goal: ""\ Input: ""],
    expected_result: [
      Distance: 0\
      Correctness: 1\
      Mistakes: none
    ],
    rows: (
      (kind: "run", result: [Distance: 0\ Correctness: NaN\ #failing]),
      (
        kind: "fix",
        description: [
          The Correctness calculation divides the distance by the length of the goal
          (to account for the fact that a long input is more likely to contain many typos).
          This resulted in NaN when that length was 0.

          Fix: clamp the division to divide by 1 instead of 0 in this case.
        ],
      ),
      (
        kind: "run",
        result: [Distance: 0\ Correctness: 1\ #passing],
      ),
    ),
  )
  test(
    name: [Very long input],
    data_category: "erroneous",
    input_data: [Goal: 1000 "a"s\ Input: 1000 "a"s],
    expected_result: [Distance: 0\ Correctness: 1\ Run Time < 100ms],
    rows: ((kind: "run", result: [Distance: 0\ Correctness: 1\ Run Time: \~70ms #passing]),),
  )
  test(
    name: [Punctuation not Considered],
    data_category: "normal",
    input_data: [Goal: "a, b!  a''"\ Input: "a b. a......"],
    expected_result: [
      Distance: 0\
      Correctness: 1\
      Mistakes: []
    ],
    rows: (
      (kind: "run", result: [Distance: 0\ Correctness: 0.12413\ #failing]),
      (
        kind: "fix",
        description: [
          The code to remove capitalisation worked fine, but in some places the original strings were used when the normalised strings were needed.
        ],
      ),
      (
        kind: "run",
        result: [Distance: 0\ Correctness: 1\ #passing],
      ),
    ),
  )
  test(
    name: [Frustrated student tries to break things],
    data_category: "erroneous",
    input_data: [Goal: 100 "a"s\ Input: 100,000 "a"s],
    expected_result: [Distance: Infinity\ Correctness: 0],
    rows: (
      (kind: "run", result: [Distance: Infinity\ Correctness: 0\ #passing]),
      (
        kind: "fix",
        description: [
          This test actually took over 100ms to run.
          That isn't a fail but I changed the code to avoid normalising such long strings.

          The test now runs in negligible time.
        ],
      ),
    ),
  )
})

== View Proxy
This is testing for the `Proxy` objects used by `World` for returning read-only views to only a subset of its cache.

Implemented in #src-file-ref("viewProxy-implementation")

The source code for the tests is in #src-file-ref("util.test.ts").

This wouldn't be important enough to deserve unit testing,
but during development I had some issues getting this area of the code working and wanted to write some unit tests for the view proxy to make sure the issue wasn't there.
These are those tests.

All these tests examine the behaviour of
```ts
viewProxy({
  0: "table[0]",
  1: "table[1]",
  a: "table.a",
  b: "table.b",
}, [0, "a"])
```

I've only listed these are 3 tests,
because they are only testing 3 different things.
The first test ensures:
- The proxy allows access only to the elements it is supposed to allow access to
- That attempting to access elements which exist but are hidden by the proxy behaves the same as attempting to access elements which never existed in the first place.
- That attempting to mutate the proxy throws some kind of error

The next test tests that `Object.entries`, `Object.keys`, and `Object.values` all behave as expected.

The final test checks that the `in` operator behaves as expected.

The reason for these particular tests is that these are the main behaviours which the proxy overrides.

#test_table({
  test(
    name: [Test view access],
    data_category: "normal",
    input_data: [
      #set raw(lang: "ts")
      Access:
      - `proxy[0]`
      - `proxy[1]`
      - `proxy[2]`
      - `proxy.a`
      - `proxy.b`
      - `proxy.c`

      Update:
      - `proxy[0]`
      - `proxy[1]`
      - `proxy[2]`
      - `proxy.a`
    ],
    expected_result: [
      #set raw(lang: "ts")
      Accesses:
      - `proxy[0] === "table[0]"`
      - `proxy[1] === undefined`
      - `proxy[2] === undefined`
      - `proxy.a === "table.a"`
      - `proxy.b === undefined`
      - `proxy.c === undefined`

      And that all those updates throw a `TypeError`.
    ],
    result: [#passing],
  )
  test(
    name: [Test view entries],
    data_category: "normal",
    input_data: [
      #set raw(lang: "ts")
      Evaluate:
      - `Object.keys`
      - `Object.values`
      - `Object.entries`
      on the proxy object
    ],
    expected_result: [
      #set raw(lang: "ts")
      Keys: `["0", "a"]`\
      Values: `["table[0]", "table.a"]`\
      Entries: `[["0", "table[0]"], ["a", "table.a"]]`
    ],
    result: [#passing],
  )
  test(
    name: [Test view has],
    data_category: "normal",
    input_data: [
      #set raw(lang: "ts")
      Check if:
      - `0 in proxy`
      - `1 in proxy`
      - `"a" in proxy`
      - `"b" in proxy`
    ],
    expected_result: [
      `0` is in `proxy`\
      `1` is not in `proxy`\
      `"a"` is in `proxy`\
      `"b"` is not in `proxy`\
    ],
    result: [#passing],
  )
})

= Acceptance Testing
#include "acceptance_testing.typ"
