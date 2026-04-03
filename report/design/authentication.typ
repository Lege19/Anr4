#import "/report/code_listing.typ": src-file-ref
#set heading(offset: 2)

Implemented in #src-file-ref("auth.rs") for the server,
or #src-file-ref("api/auth.ts") for the client.

Although currently this is only expected to run as a monolithic server,
and one using SQLite for which querying the database is much faster than when the database is remote,
I am opting to use Access Tokens instead of Session Tokens.

/ Session Token:
  A session token is a randomly generated string which is stored in the database and returned to the client after a successful login attempt.
  When the client makes a request, it includes the session token in an HTTP header,
  and the server checks that the token is recognised by the database,
  what account it is for,
  and that it has not expired.

/ Access Tokens:
  Access tokens are more popular these days,
  as they are more geared towards the increasingly popular microservice model for the internet,
  where the servers that process the API requests may be separate from the server that deals with authentication.

  The data that would be stored in the database with a session token
  (most importantly user id and expiration date, although other fields are common too)
  is instead encoded in some way in the token itself,
  which is signed by the server.
  The information is known as the "claims".

  A common form of accoss token is the JSON Web Token, these encode the claims in JSON.
  This is then signed, and the signature, along with potentially other informition,
  is also encoded into JSON. The header and the claims are then encoded using base64 for some reason.

  I'm not sure what the point of the base64 bit is because it doesn't provide any extra security,
  but I'm going along with it.

The main benefit of Access Tokens is that they allow for authentication without storing anything in the database,
and more importantly that they allow the server to authenticate requests without reading from the database.

There are many ways to make access tokens more secure,
and many options for how to store them on the client.
I am not going to detail this decision process, just the result.

= Access Tokens
The claims are:
- Account ID
- Account kind (teacher or student)
- Fingerprint (explained later)
- Expiration timestamp

The only way which access token based security can be compromised is if an attacker manages to steal an access token before its expiration.
There are many ways to mitigate this.
== XSS and CSRF
XSS stands for CROSS Site Scripting,
which is more understandable as code injection.

An attacker gets malicious code to run in the context of the site being targeted,
with access to the cookies, session data, local storage, global variables, etc, of that site.

If the access token can never be accessed from JavaScript,
then it cannot be stolen even in a successful XSS attack.

CSRF stands for Cross Site Request Forgery.
In a CSRF attack, a malicious site makes a request to the back-end of the site being targeted.
If the authentication is Cookie based and does not use extra protections to prevent this
--- such as SameSite cookies
--- this will succeed, allowing the malicious site to send authenticated requests.

== Expiration Time
Using a short expiration time --- 15 minutes is common
--- means that even if an attacker can steal an access token,
it will only be valid for a relatively short amount of time.

This is of course bad for users though, as they would have to get a new access token every 15 minutes.
This in turn is mitigated using a Refresh Token.
This works much like the traditional session token,
however refresh tokens are single use,
and since they are only used every 15 minutes it doesn't matter if they are a bit slower.

It may look like the use of refresh tokens defeats the point of having short lived access tokens,
the reason this is not the case is that since refresh tokens are single use,
and are not being sent around much,
they are inherently harder for an attacker to steal than an access token.

== HttpOnly Cookies
It's possible to store the access token in a cookie which cannot be accessed via JavaScript.
This is a widely supported security feature designed to defend against XSS attacks.

If the cookies are also marked as SameSite, then this is also resistant to CSRF.

The downside is that the access token contains useful information which the clients should have access to.

== Fingerprints
One way to get the best of both worlds is to store the Access Token in session storage
(which is not resistant to XSS), is to use a randomly generated fingerprint.

When a new access token is created, the fingerprint is randomly generated using cryptographically secure randomness.

This is then hashed, and base 64 encoded, and stored as one of the claims in the access token
--- and is thus signed along side the other claims.
Then the unhashed fingerprint is sent to the client in an HttpOnly, SameSite cookie.

Since the cookie is HttpOnly, it can never be read by client side JavaScript, and is thus resistant to XSS.
Since the cookie is SameSite, it is only ever sent from the issuing site (Anr4) to the issuing server (the back-end),
which prevents CSRF attacks.

Then the server can check that when it hashes the fingerprint from the cookie,
the result matches the fingerprint in the claims.

Hashing the fingerprint is necessary so that if the access token is compromised,
an attacker can't just recreate the fingerprint token by copying it from the access token.

As I understand it, using fingerprints in this way allows me to have the security of storing the access token in a HttpOnly, SameSite cookie,
while still allowing the client to read the access token claims.

