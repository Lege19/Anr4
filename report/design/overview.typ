#import "@preview/fletcher:0.5.8": diagram, edge, node

#show link: set text(black)
#figure(
  diagram(
    node-stroke: 1pt,
    edge-stroke: 1pt,
    spacing: (2em, 2em),
    {
      let library = (stroke: teal, fill: teal.lighten(90%))
      let edge = edge.with(marks: "-<|-")
      node(
        (0, 0),
        enclose: (
          <sqlite-node>,
          <sqlx-node>,
          <auth-node>,
          <server-api-node>,
          <router-node>,
          <vite-rs-axum-node>,
          <server-front-node>,
          <axum-server-node>,
          <hyper-node>,
        ),
        name: <server-node>,
        inset: 1em,
      )
      node(<server-node.north>, fill: white, stroke: none)[Server]

      node((rel: (0, -1), to: <server-node>), name: <sqlite-node>, ..library, link(<database-libs>)[SQLite])
      edge()
      node((rel: (0, 0), to: <server-node>), name: <sqlx-node>, ..library, link(<database-libs>)[SQLx])
      node((rel: (1, 1), to: <server-node>), name: <auth-node>, link(<authentication-system>)[Authentication\ Module])
      node((rel: (0, 1), to: <server-node>), name: <server-api-node>, link(<API-specification>)[API\ Module])
      edge()
      node((rel: (0, 2), to: <server-node>), name: <router-node>)[Router\ Module]
      edge(marks: "-")
      node((rel: (1, 2), to: <server-node>), name: <vite-rs-axum-node>, ..library, link(
        <axum-and-related>,
      )[Vite-rs Axum])
      node((rel: (0, 3), to: <server-node>), name: <server-front-node>)[Server Front]
      edge(marks: "-")
      node((rel: (0, 4), to: <server-node>), name: <axum-server-node>, ..library, link(<axum-and-related>)[Axum Server])
      edge(marks: "-")
      node((rel: (0, 5), to: <server-node>), name: <hyper-node>, ..library, link(<axum-and-related>)[Hyper])

      edge(<sqlx-node>, <server-api-node>)
      edge(<router-node>, <server-front-node>, marks: "-")
      edge(<sqlx-node.south-east>, <auth-node.north-west>)
      edge(<auth-node>, <server-api-node>)

      edge(<port-443>, <port-80>, label: [Redirect], bend: -20deg, stroke: (dash: "dashed"))

      node(
        (-1, 9),
        enclose: (
          <client-api-node>,
          <ui-components-node>,
          <solidjs-node>,
          <browser-node>,
          <learning-model-node>,
          <spelling-algorithm-node>,
        ),
        name: <client-node>,
        inset: 1em,
      )
      node(<client-node.south>, fill: white, stroke: none)[Client]
      node((rel: (0, 0), to: <client-node>), name: <client-api-node>, link(<client-api-module>)[API\ Module])
      edge()
      node(
        (rel: (1, 0), to: <client-node>),
        name: <ui-components-node>,
        stroke: (dash: "dashed"),
        fill: tiling(image("ui-component-tiling.svg")),
        link(<ui-components-design>)[#place(center + horizon, text(stroke: white + 4pt)[UI\ Components])UI\ Components],
      )
      edge()
      node((rel: (2, 0), to: <client-node>), name: <solidjs-node>, ..library, link(<solidJS>)[SolidJS])
      edge()
      node((rel: (3, 0), to: <client-node>), name: <browser-node>, stroke: red, fill: red.lighten(90%))[Browser]

      node((rel: (1, 1), to: <client-node>), name: <spelling-algorithm-node>, link(
        <spelling-algorithm-design>,
      )[Spelling\ Algorithm])
      node((rel: (0, 1), to: <client-node>), name: <learning-model-node>, link(
        <learning-model-design>,
      )[Learning\ Model])
      edge(<learning-model-node.north-east>, <ui-components-node.south-west>)
      edge(<spelling-algorithm-node>, <ui-components-node>)
      edge(<client-api-node>, <learning-model-node>)

      node((0, 8), name: <https-anchor-node>)

      node(
        (<server-node.south>, "-|", (0, 0)),
        name: <port-443>,
        stroke: none,
        fill: white,
        inset: 0.2em,
      )[Port 443]
      node(
        (<server-node.south>, "-|", (1, 0)),
        name: <port-80>,
        stroke: none,
        fill: white,
        inset: 0.2em,
      )[Port 80]
      edge(
        <port-80>,
        (rel: (0, 1), to: <port-80>),
        (rel: (1, 1), to: <port-80>),
        <browser-node>,
        marks: (),
        stroke: (dash: "dashed"),
        label: [HTTP],
      )

      edge(<port-443>, <hyper-node>, marks: ())
      edge(<https-anchor-node>, <port-443>, marks: ())

      edge(
        <https-anchor-node>,
        <client-api-node>,
        corner: left,
        label: [HTTPS],
        label-pos: 0.3,
        marks: ((inherit: "solid", pos: 0.3),),
      )
      edge(
        <https-anchor-node>,
        <browser-node>,
        corner: right,
        label: [HTTPS],
        label-pos: 0.3,
        marks: ((inherit: "solid", pos: 0.3),),
      )
      edge(<server-api-node>, <client-api-node>, bend: -40deg, floating: true, stroke: (dash: "dashed"), label: [JSON])
      //edge(
      //  <server-api-node>,
      //  <client-api-node>,
      //  bend: -40deg,
      //  floating: true,
      //  stroke: none,
      //  label: rect(
      //    ..library,
      //    link(<other-libraries-decoders>)[Decoders],
      //  ),
      //  label-pos: 85%,
      //  label-side: center,
      //  label-angle: bottom,
      //)
      edge(<vite-rs-axum-node>, <browser-node>, bend: 40deg, floating: true, stroke: (dash: "dashed"))
    },
  ),
  caption: [
    A diagram showing the major components of the client and server,
    as well as the communication between these
  ],
)
This diagram shows this which major components will communicate.
The dashed lines indicate logical communication and the solid lines indicate more direct communication.
Libraries are shown in blue.

In practice some of these components may be split across multiple "modules" at the language level,
but these are the units of encapsulation and independence that I am aiming to write to.

The server block is everything that runs on the server and the client block is everything that runs on the client.

Arrows indicate what makes calls to what, not the flow of data.
I've omitted them in some cases because it is an arbitrary distinction when higher order functions are involved.

- SQLite is the database. Since SQLite is serverless I've shown it inside the server.
- SQLx is the library I'm using to interact with SQLite.
  It will make my life much easier if I decide to migrate to a different database in future.
- The Authentication Module handles everything relating to user authentication.
  - Hashing and checking passwords
  - Creating JSON Web Tokens (JWTs)
  - Creating Fingerprint Cookies
  - Authenticate users from their fingerprint and JWT.
  - Allow API code to read the claims made in a JWT
  - Provide a convenient interface for this functionality
- The API module exports an Axum router that is nested to handle all `/api` URLs.
  Various database queries needed by clients are implemented here and some other requests are forwarded to the Authentication Module.
- The Router Module defines the overall router, which forwards requests for `/api` URLs to the API router,
  and other requests to Vite-rs Axum.
  This is the entry point to the server (the main function).
  After constructing the master router it passes it to the Server Front.
- The Server Front is a boilerplate module.
  It's responsible for starting and stopping the server and for setting up a secondary server that listens on port 80 to redirect requests made with HTTP to use HTTPS instead.
  So this module is only involved in startup and shutdown.
- The Client API module contains wrappers for communication with the server's API module.
  Putting this in a separate module also means it would be easier to change serialisation protocol in future
  (e.g. use Protobuf instead of JSON)
- The Learning Model is responsible for choosing words to test the student on.
  I've shown this on the client,
  because all the computation relating to this will happen on the client.
  However, the design of this will necessarily have some influence on the design of the database.
- The Spelling Algorithm just has to calculate the "typo distance" between strings.

UI Components gets a dashed box because it will not be a single module
but many small modules that each export a single UI component.
