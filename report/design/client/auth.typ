#import "../../template.typ": sidenote
#import "../../code_listing.typ": src-file-ref

Implemented in #src-file-ref("api/auth.ts")

The client needs a robust system for sending authenticated requests,
and handling the failure of these.

The fingerprint cookie is automatically sent back to the server on every request
--- that's how cookies work.
The access token has to be sent to the server manually.
Any way to do this is as good as any other,
I've decided to use the `Authorization` header.
It looks like there are some conventions for what goes in this,
but the client can set it to anything and the server can interpret it how it likes.
It also looks like the convention to follow in this case would be to set it to #box(`Bearer <ACCESS TOKEN>`),
I don't know why but I'll go along with it.

The interface for the `Auth` class shall be
```ts
class AuthFailureException extends Error {}
class DoubleLogInException extends Error {}
class DoubleLogOutException extends Error {}

class AccessToken {
  public readonly token: string;
  public readonly claims: AccessTokenClaims;
  constructor(src: string);
}

type AuthFailureHandler = (
  old: AccessToken | undefined,
) => Promise<AccessToken | undefined>;

class Auth {
  // signals
  /**
   * Reactive signal to the currently in use access token.
   */
  public readonly accessToken: Accessor<AccessToken | undefined>;

  // memos
  public readonly accountId: Accessor<RowId | undefined>;
  public readonly studentId: Accessor<RowId | undefined>;
  public readonly teacherId: Accessor<RowId | undefined>;

  constructor();

  /**
   * Perform an HTTPS request,
   * parameters and return type are modelled after the JavaScript fetch API
   * @throws AuthFailureException if authentication fails and cannot be recovered
   */
  public async fetch(
    input: RequestInfo | URL,
    init?: RequestInit,
  ): Promise<Response>;

  public addAuthFailureHandler(handler: AuthFailureHandler);
  public removeAuthFailureHandler(handler: AuthFailureHandler);
  /**
   * Sign in using the provided access token.
   *
   * @param newAccessToken - The new access token signed in with
   * @throws a DoubleLogInException if there is already an access token
   */
  public logIn(newAccessToken: AccessToken);
  /**
   * Sign out
   * @throws a DoubleLogOutException if already signed out
   */
  public logOut();
}
```
The idea with `addAuthFailureHandler` and `removeAuthFailureHandler` is that in a few cases, authentication failures can be handled gracefully.
With refresh tokens, the first thing to try when authentication fails is to use the refresh token to obtain a new access token and refresh token pair.
If this also fails, the next thing to try would be to open a login pop-up to ask the user to log in again.

When there is an authentication failure,
`fetch` should call each of the authentication failure handlers registered with `addAuthFailureHandler`,
each of these will attempt to get a new access token by some means or other.
If any are successful and return a new access token, the request is attempted again.

Making authentication failure handlers asynchronous allows them to take an unbounded length of time to return,
which is useful for the login pop-up which must wait for user input.

The handlers themselves are not very interesting.
