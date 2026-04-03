#import "../../template.typ": sidenote
#import "@preview/codly:1.3.0"
#set heading(offset: 3)

= Validation
It's sensible to validate all incoming JSON.

I have previously written this validation code by hand.
This is sufficiently annoying to do that there are several libraries to help with it.
I mentioned earlier that I would use Decoders for this.

Decoders is based off a decoder type `Decoder<T>`,
and then provides several functions for constructing more complex `Decoder`s from simpler `Decoder`s.

#sidenote[
  For example, in the final code I have
  #codly.local(
    number-format: none,
    ```ts
    export const studentInfoDecoder = d.object({
      studentId: rowIdDecoder,
      schoolId: rowIdDecoder,
      isDyslexic: d.nullable(d.boolean),
      forename: d.string,
      surname: d.string,
      cohorts: d.record(
        rowIdDecoder,
        d.object({
          tier: d.positiveInteger,
          classId: rowIdDecoder,
        }),
      ),
    });
    ```,
  )
]

The nice thing about this is that it mirrors the syntax of regular TypeScript types,
and it also allows me to leverage TypeScript's type inference to infer the type the decoder is validating:

#codly.local(
  number-format: none,
  ```ts
  type ExtractType<T> = T extends Decoder<infer X> ? X : never
  ```,
)

#sidenote[
  So in the final code, I can write
  #codly.local(
    number-format: none,
    ```ts
    export const studentInfoDecoder = /*above*/;
    export type StudentInfo = ExtractType<typeof studentInfoDecoder>;
    ```,
  )

  And `StudentInfo` is correctly inferred to be equivalent to:
  #codly.local(
    number-format: none,
    ```ts
    export type StudentInfo = {
      studentId: string;
      schoolId: string;
      isDyslexic: boolean | null;
      forename: string;
      surname: string;
      cohorts: Record<string, {
        tier: number;
        classId: string;
      }>;
    };
    ```,
  )
]

One submodule of the client API module will just have the Decoder definitions of all the message types the client needs to receive.
These are exported alongside the types inferred for them.

= Fetchers
Another module will have functions which wrap the raw API routes from the server.

These are not at all interesting.

For each API route provided by the server (see @API-specification) there is a function with the appropriate signature and return type.

#sidenote[
  I made this code slightly less horribly repetitive with some helper higher functions:
  ```ts
  const JSON_CONTENT_TYPE = {
    "Content-Type": "application/json;charset=UTF-8",
  };
  const postJson =
    <T extends d.JSONValue>(url: string) =>
    (json: T) =>
      new Request(url, {
        method: "POST",
        headers: JSON_CONTENT_TYPE,
        body: JSON.stringify(json),
      });

  async function fetchAndDecode<T>(
    resource: RequestInfo | URL,
    decoder: Decoder<T>,
  ): Promise<T> {
    const response = await Auth.fetch(resource);
    const decoded = decoder.decode(await response.json());
    if (decoded.ok) return decoded.value;
    throw new APIDecodeError(JSON.stringify(decoded.error));
  }

  const makeFetchAndDecode =
    <T, F extends unknown[]>(
      resource: (...args: F) => RequestInfo | URL,
      decoder: Decoder<T>,
    ) =>
    (...args: F) =>
      fetchAndDecode(resource(...args), decoder);
  ```
  CURRY!

  These are then used like
  ```ts
  const topics = makeFetchAndDecode(
    postJson<{ tier: number | null; topics: RowId[] }>("/api/data/topics"),
    d.array(topicDecoder),
  );

  ```
]

= World
I needed some kind of cache which understood how these requests worked.
For simple cases, this can be done using `query` by Solid Router.
However this only works for requests which are actually the same,
but since most of these accept a list of IDs to retrieve information about,
it's possible for two requests to have significant overlap without actually being the same.
I needed a custom solution.

I present, the `World`.

This is not very interesting either, but it's worth describing how it works.

For each of the main types of resource that need to be loaded:
- Cohort
- Course
- Topic
- Word
- Progress
`World` will provide functions for retrieving data from these,
which use the cached values if available, and otherwise request only the items not already cached and add these to the cache.
- `loadNeeded`: Of the requested keys,
  compute which are not currently in the cache, and request those using `loadExact`.
  Then return a read-only view into the cache with only the requested keys visible#footnote[
    This uses JavaScript's `Proxy` object feature.
  ].
- `loadExact`: Request exactly these keys, regardless of whether they are already in the cache,
  the new values are added to the cache, overwriting the previous values if they were already cached.
- `get`: Return the corresponding data for a particular key,
  this internally just calls loadNeeded with just 1 key.

All these functions will be asynchronous, since they may need to fetch data from the back-end.

For each of those data categories there'll be an internal cache object with keys corresponding to the database keys and values corresponding to rows in the database.

For progress, there'll need to be some extra functionality because progress values are expected to change.
As well as the main cache, it will also be necessary to keep track of for which words the progress has been changed, and hence needs to be sent to the server.
There'll then be two methods `setProgress` and `pushChangedProgress`.
The former updates the progress for a particular word, and adds that to the set of words for which the progress has changed.
The latter checks if there have been any changes, and if there are it sends those to the back-end and resets the set of changes back to empty.

`pushChangedProgress` clearly needs to be asynchronous, since it is communicating with the server.
`setProgress` probably doesn't need to be asynchronous, but I'm inclined to make it asynchronous anyway because that's annoying to changed later.

It's important to not that all the entries here are *immutable*.
That is, an object of type `Progress` will never be mutated,
you always build a new one from scratch.

Using mutable `Progress` values _could_ have better performance,
but I think mutability would bo more likely to introduce bugs than I'm willing to tolerate.

The same goes for `Cohort`s, `Course`s, etc, but for these there's no reason why they would ever need to change anyway.


== Account Information
The authentication system will only deal with access tokens,
this means that key account information such as name and which courses a student studies are not managed.

However while most of the data is not necessarily needed and may be loaded lazily,
some information is pretty much guaranteed to be needed and should be set off loading as soon as the user logs in.

This can be further split into two parts,
the core information roughly corresponding to the `Teacher` and `Student` tables,
and the information which will be loaded in subsequent queries based of this.

=== Teacher Information
For a teacher, the core information is their forename, surname, and the school their account is attached to.
After that, the classes they teach are loaded,
from these the cohorts they are involved with can be found and loaded,
and finally the courses those cohorts study are loaded.

Instead of being made available as an asynchronous function,
I'll wrap this behind a `createAsync` (this is another function from Solid Router),
which turns a `Promise` into a reactive SolidJS signal.

This is because this information is more likely to be used in the user interface surface
(which works well with signals)
rather than in the learning model
(which is asynchronous anyway and hence works well with promises)

#sidenote[
  Since I ran out of time to implement most of the teacher interface,
  I didn't write the code for this to load more than just the core information.
]

=== Student Information
The core information for a student account is much the same, forename, surname and school,
but also for students whether they are marked as dyslexic.
Then cohorts and courses follow easily.
