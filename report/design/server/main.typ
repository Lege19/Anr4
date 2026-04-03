#import "../../template.typ": DEV_MODE, code_box, sidenote

#set heading(offset: 2)
#set raw(tab-size: 4)

= Tools/Libraries/Frameworks/Languages to use
The server will be hosted on a Virtual Private Server (VPS) for the foreseeable future,
these often provide very minimal system resources
(1GB of ram and a single CPU core would be typical).
Almost all garbage collected languages "stop the world" to collect garbage.
This isn't ideal because I'll already be restricted for CPU time on the VPS.
Of non-garbage-collected languages,
I'm the most familiar with Rust, so I'll be using that.

== Framework <axum-and-related>
Within Rust, there are a few good options for server frameworks, namely
#link("https://github.com/tokio-rs/axum")[Axum],
#link("https://actix.rs/")[Actix], #link("https://rocket.rs/")[Rocket] and
#link("https://github.com/seanmonstar/warp")[Warp]. I think this is a fairly
arbitrary decision as they all do fairly similar things and have very similar
performance, the main differences are the ecosystem and API. I chose Axum.

Axum builds on the #link("https://github.com/tower-rs/tower")[Tower] ecosystem. As
well as using the base Axum crate, I'll also use
#link("https://docs.rs/axum-extra/0.10.1/axum_extra")[Axum Extra],
#link("https://docs.rs/axum-server/0.7.2/axum_server")[Axum Server],
#link("https://docs.rs/axum-csp/0.0.10/axum_csp")[Axum CSP],
and #link("https://docs.rs/vite-rs-axum-0-8/0.2.1/vite_rs_axum_0_8/")[vite-rs Axum]

Tower defines a set of abstractions for working with asynchronous functions taking a
request as input, and returning a response as output.

Axum uses the abstractions defined by Tower to create a convenient interface for
describing the routing and request handling in a HTTP server. By building on
Tower, Axum servers can integrate with a huge range of other libraries that also
provide Tower-based interfaces.

Axum Extra provides various extra utilities missing from Axum.

#link("https://hyper.rs/")[Hyper] is a set of low level APIs for receiving and
responding to HTTP and HTTPS requests.

Axum Server joins Axum to Hyper.

Axum CSP is a tiny utility crate to make it easier to write
#link("https://developer.mozilla.org/en-US/docs/Web/HTTP/Guides/CSP")[Content Security Policy]
headers.

Vite-rs is a crate for integrating Vite with Rust.
This is useful because it allows me to benefit from the Vite hotreloading while still accessing the Rust server for the API.
Vite-rs Axum is a specialisation of Vite-rs made specifically for Axum servers.

== Asynchronous Runtime
_In most languages that support asynchronous code this is built into the
language. I'm including this for completeness but it's not important._\
Axum locks me into using #link("https://tokio.rs/")[Tokio].

== Database <database-libs>
I'll be using #link("https://sqlite.org/")[SQLite] because it is easier to
deploy than alternatives and should be easily capable of handling the low amount
of traffic.

To interact with SQLite from the server I'll use
#link("https://github.com/launchbadge/sqlx")[SQLx]. This crate supports multiple
databases, which will make switching to a heavier database easier if that
becomes necessary. It also validates my SQL against the SQLite database schema
at compile time to catch bugs in my SQL early, and can automatically generate
Rust datatypes reflecting the structure of the records in the database.

#sidenote[
  In the end, I actually used #link("https://github.com/Lege19/sqlx")[my own fork of SQLx].

  This fixed a bug in the SQLite type inference.
  In general, primary keys are nullable in SQLite,
  however this does not apply to `INTEGER` primary keys,
  which become aliases to the internal `rowid` column,
  and are therefore not nullable.

  The existing implementation did not consider this exception.
]

== Data Serialization Framework
I'll use #link("https://serde.rs/")[Serde] because it is integrated into Axum,
allowing me to return a Rust struct as an HTTP response from the server with no
boilerplate, or receive the body of a request as a Rust struct - automatically
enforcing the expected structure of the request body.

Serde is very convenient to use because it provides macros to write the
serialization boilerplate for my Rust data types, these even supports useful
customisations such as automatically rewriting field names from `snake_case`
(Rust convention) to `camelCase` (TypeScript convention).

It's also very flexible, a problem I'll encounter is that SQLite uses 64-bit
signed integers as IDs, but these cannot be accurately represented in TypeScript
(all numbers are represented as 64-bit floats), so they are commonly converted
to a string first. Serde allows me to do this automatically.

= Code Structure
On the grounds that the person reading this probably doesn't know Rust. I've
taken some liberties in displaying this information in a way that should be
more self explanatory than valid Rust syntax would be.

Rust is generally either like Haskell or like C++.

#table(
  columns: 2,
  table.header([*Features with Haskell parallels*], [*Features with C++ parallels*]),
  [
    // Haskell
    - Rust ```rust trait```s #sym.arrow Haskell ```haskell class```es
    - Rust ```rust struct```s #sym.arrow Haskell ```haskell data``` variants\
      A Rust struct can be a unit struct (no fields, so only one possible
      value), a tuple struct (one or more unnamed elements), or record-like (one
      or more named fields).
    - Rust ```rust enum```s #sym.arrow Haskell ```haskell data```types\
      The variants of a Rust enum are a lot like Rust structs - in that they can
      be unit variants with no associated data, tuple variants with unnamed
      associated data, or record variants with named associated data.
    - Rust generics #sym.arrow Haskell polymorphic types and functions
  ],
  [
    // C++
    - Rust move semantics #sym.arrow C++ move semantics\
      Although in Rust it's the default.
    - Rust ```rust Drop``` trait #sym.arrow C++ destructors\
      Rust also has smart pointers much like those in C++ using this mechanism.
      However Rust's smart pointers not only ensure the memory is correctly
      dropped, but that there are no dangling pointers, or concurrent writes,
      etc.
    - Rust references #sym.arrow C++ references\
      But Rust's references make much stronger safety guarantees, and sometimes
      require explicit creation and dereferencing.
    - Rust trait objects #sym.arrow C++ dynamic dispatch of virtual methods
  ],
)
Rust lifetimes don't fit into either of these categories, they are not important here.


#if not DEV_MODE {
  include "./docsgen.typ"
}

```rs
fn get_redirect_uri(host: &str, uri: Uri, https_port: u16)
    -> Result<Uri, GetRedirectUriError>;
```
