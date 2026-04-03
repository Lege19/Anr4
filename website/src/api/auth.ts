import {
  accessTokenClaimsDecoder,
  AccountKind,
  type AccessTokenClaims,
  type RowId,
} from "./types";
import { InvalidTokenError, jwtDecode } from "jwt-decode";
import {
  createMemo,
  createRoot,
  createSignal,
  type Accessor,
  type Setter,
} from "solid-js";

export class AccessToken {
  public readonly token: string;
  public readonly claims: AccessTokenClaims;
  constructor(src: string) {
    this.token = src;
    this.claims = AccessToken.decodeAccessToken(this.token);
  }

  private static decodeAccessToken(token: string): AccessTokenClaims {
    const decoded = accessTokenClaimsDecoder.decode(jwtDecode(token));
    if (decoded.ok) {
      return decoded.value;
    } else {
      throw new InvalidTokenError("Claims are not in the expected format");
    }
  }
}

/**
 * Functions that can attempt to generate a new accessToken on authentication failure
 */
type AuthFailureHandler = (
  old: AccessToken | undefined,
) => Promise<AccessToken | undefined>;
/**
 * A set of promise returning functions to call in an attempt to get a new access token.
 */

export class AuthFailureException extends Error {}
export class DoubleLogInException extends Error {}
export class DoubleLogOutException extends Error {}
class AuthManager {
  // signal
  public readonly accessToken: Accessor<AccessToken | undefined>;
  private readonly setAccessToken: Setter<AccessToken | undefined>;

  private readonly authFailureHandlers = new Set<AuthFailureHandler>();

  // memos
  public readonly accountId: Accessor<RowId | undefined>;
  public readonly studentId: Accessor<RowId | undefined>;
  public readonly teacherId: Accessor<RowId | undefined>;

  constructor() {
    [this.accessToken, this.setAccessToken] = createSignal<
      undefined | AccessToken
    >();
    this.accountId = createMemo(() => this.accessToken()?.claims.id);
    this.studentId = createMemo(() => {
      const claims = this.accessToken()?.claims;
      if (claims === undefined) return;
      if (claims.kind !== AccountKind.Student) return;
      return claims.id;
    });
    this.teacherId = createMemo(() => {
      const claims = this.accessToken()?.claims;
      if (claims === undefined) return;
      if (claims.kind !== AccountKind.Teacher) return;
      return claims.id;
    });
  }

  private attemptFetchWithAuth(
    input: RequestInfo | URL,
    init?: RequestInit,
  ): Promise<Response> {
    const tmp = this.accessToken();

    if (!tmp) throw new AuthFailureException("No access token availible");

    const req = new Request(input, init);
    const url = new URL(req.url);

    if (url.host != location.host || url.hostname != location.hostname)
      throw new AuthFailureException(
        "Attempt to authenticate request to an unknown server",
      );

    if (url.protocol != "https:")
      throw new AuthFailureException("Attempt to authenticate without HTTPS");

    req.headers.set("Authorization", `Bearer ${tmp.token}`);

    return fetch(req);
  }
  public async fetch(
    input: RequestInfo | URL,
    init?: RequestInit,
  ): Promise<Response> {
    const maxAttempts = 5;
    retry: for (let attempts = 0; attempts < maxAttempts; attempts++) {
      try {
        const response = await this.attemptFetchWithAuth(input, init);
        if (response.status == 401 /*unauthorized*/)
          throw new AuthFailureException(
            "Invalid access token (status 401 recieved)",
          );
        return response;
      } catch (error) {
        if (!(error instanceof AuthFailureException)) throw error;
        for (const handler of this.authFailureHandlers) {
          let token;
          try {
            token = await handler(this.accessToken());
          } catch (error) {
            console.warn(
              "Authentication failure handlers should not throw, return undefined instead. Handler threw:",
              error,
            );
          }
          if (token) {
            this.setAccessToken(token);
            continue retry;
          }
        }
        this.setAccessToken(undefined);
        throw error;
      }
    }
    throw new AuthFailureException(
      `Authentication failed after ${maxAttempts} attempts`,
    );
  }
  public addAuthFailureHandler(handler: AuthFailureHandler) {
    this.authFailureHandlers.add(handler);
  }
  public removeAuthFailureHandler(handler: AuthFailureHandler) {
    this.authFailureHandlers.delete(handler);
  }
  /**
   * Sign in using the provided access token.
   *
   * @param newAccessToken - The new access token signed in with
   * @throws a {@link DoubleLogInException} if there is already an access token
   */
  public logIn(newAccessToken: AccessToken) {
    this.setAccessToken((prev) => {
      if (prev) throw new DoubleLogInException();
      return newAccessToken;
    });
  }
  public logOut() {
    this.setAccessToken((prev) => {
      if (!prev) throw new DoubleLogOutException();
      return undefined;
    });
  }
}

export const Auth = createRoot(() => new AuthManager());
