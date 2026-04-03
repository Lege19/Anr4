#import "code_listing.typ": src-file-ref

The full code listing is availible in #link(<full-code-listing>)[Appendix A].

This section will contain links to particularly interesting parts of the code.

To make getting back here easier, I've put links back to this section in the page headers of the code listings.

The most interesting part of the code is #src-file-ref("algorithms/correctness.tsx"),
this is the implementation for the correctness algorithm and contains the bulk of the *algorithmic complexity*.

The *database schema* is in #src-file-ref("initialise.sql"),
this has *16 tables*, *4* of which are *link tables*, with a total of *21 foreign key references*.

There is a *complex client-server model*, mainly implemented in #src-file-ref("api.rs"),
#src-file-ref("api/queries.rs"),
#src-file-ref("api/index.ts"),
and #src-file-ref("api/types.ts").
Which has *9 distinct API calls*, *6* of which *are parameterised* using JSON POST requests.

The server uses a total of *20 query parameters* across *14 parameterised queries*,
which use *6 join clauses*.

There is also *algorithmic complexity* in #src-file-ref("components/MultilingualInput.tsx") and in #src-file-ref("algorithms/learningModel.ts").

I have used *higher order functions* in #src-file-ref("api/index.ts") and in #src-file-ref("api/auth.ts") #footnote[
  I've actually used higer order functions pretty much everywhere,
  because that's just how you get basic things done in SolidJS.
].

I'm not sure if I can get credit for these, but I've also used some advanced features of SolidJS.
#src-file-ref("loginPopupAuthFailureHandler.tsx") uses creation and correct disposal of a secondary rendering root.
