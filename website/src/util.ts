import {
  createMemo,
  type JSX,
  type Accessor,
  untrack,
  children,
  createComponent,
} from "solid-js";

/**
 * Run a callback every `period` milliseconds, and before page exit (if possible)
 * returns a function which can be used to stop calling the callback
 */
export function runPeriodicallyAndBeforeExit(
  callback: () => void,
  period: number,
): () => void {
  let refreshTimeout = () => {
    callback();
    setTimeout(refreshTimeout, period);
  };
  addEventListener("beforeunload", callback);
  refreshTimeout();
  return () => {
    refreshTimeout = () => {};
    removeEventListener("beforeunload", callback);
  };
}

function isNotNullish<T>(t: T): t is NonNullable<T> {
  return t !== null && t !== undefined;
}
// My initial version of this function was:
// ```typescript
// export function RenderOnceShow<T>(props: {
//   when: NonNullable<T> | undefined;
//   fallback?: JSX.Element;
//   children: (t: Accessor<NonNullable<T>>) => JSX.Element;
// }) {
//   // Avoid unneccessary re-renders of the fallback
//   const fallback = children(() => props.fallback);
//
//   // TRACKS: the first time props.when changes from undefined to defined
//   return createMemo(() => {
//     const when = untrack(() => props.when);
//
//     if (when !== undefined) {
//       // nothing is tracked here.
//       // so once this branch has run the memo will never run again.
//       const [t, setT] = createSignal<NonNullable<T>>(when);
//
//       // memo here so props.children is only called once
//       // TRACKS: props.children
//       const content: Accessor<JSX.Element> = createMemo(() => {
//         // track the access to children
//         const children = props.children;
//         return createComponent(children, t);
//       });
//       // each time props.when changes,
//       // setT, so long as props.when is not undefined
//       createComputed(() => {
//         const when = props.when;
//         if (when === undefined) return;
//         setT(() => when);
//       });
//
//       // TRACKS: props.when, fallback, content
//       return createMemo(() =>
//         props.when === undefined ? fallback() : content(),
//       );
//     } else {
//       // this is the only tracked signal in this memo
//       // putting props.when behind a createMemo ensures that the outer memo
//       // only re-evaluates if props.when is no longer undefined
//       createMemo(() => props.when)();
//       return fallback();
//     }
//   }) as unknown as JSX.Element; // Apparently this is ok? `Show` does it.;
// }
// ```
//
// This was simplified to the final code with some suggestions from _bigmistqke_ on the
// public SolidJS discord server.
//
// Original conversation: https://discord.com/channels/722131463138705510/1455512464711221378
//
// REFERENCE AS <RenderOnceShow-primitive-implementation>
export function RenderOnceShow<T>(props: {
  when: T;
  fallback?: JSX.Element;
  children: (t: Accessor<NonNullable<T>>) => JSX.Element;
}) {
  // Avoid unneccessary re-renders of the fallback
  const fallback = children(() => props.fallback);

  // TRACKS: the first time props.when changes from undefined to defined
  return createMemo(() => {
    const when = untrack(() => props.when);

    if (isNotNullish(when)) {
      const t = createMemo<NonNullable<T>>((prev) => props.when ?? prev, when);

      // memo here so props.children is only called once
      // TRACKS: props.children
      const content: Accessor<JSX.Element> = createMemo(() =>
        createComponent(props.children, t),
      );

      // TRACKS: props.when, fallback, content
      return createMemo(() =>
        isNotNullish(props.when) ? content() : fallback(),
      );
    } else {
      // this is the only tracked signal in this memo
      // eslint-disable-next-line @typescript-eslint/no-unused-expressions
      props.when;
      return fallback();
    }
  }) as unknown as JSX.Element; // Apparently this is ok? `Show` does it.
}

export function assertDefined<T>(t: T | undefined): T {
  if (t === undefined) {
    throw new TypeError("Not undefined assertion failed");
  }
  return t;
}

function coerceToKey<O extends object>(key: keyof O): string | symbol {
  if (typeof key === "symbol" || typeof key === "string") return key;
  return key.toString();
}

// REFERENCE AS <viewProxy-implementation>
export function viewProxy<O extends object, K extends keyof O>(
  object: O,
  keys: K[],
): { readonly [V in K]: O[V] } {
  const stringKeys = keys.map(coerceToKey<O>);
  const keySet = new Set(stringKeys);

  const handler: ProxyHandler<O> = {
    get(target, prop) {
      if (keySet.has(prop)) return Reflect.get(target, prop);
    },
    set: () => {
      throw new TypeError("View is readonly");
    },
    has(_, prop) {
      return keySet.has(prop);
    },
    ownKeys() {
      return stringKeys;
    },
    defineProperty() {
      throw new TypeError("View is readonly");
    },
    preventExtensions() {
      throw new TypeError("Cannot prevent extensions on view");
    },
    getOwnPropertyDescriptor(target, prop) {
      if (keySet.has(prop)) {
        const out = Reflect.getOwnPropertyDescriptor(target, prop);
        return out;
      }
    },
  };
  return new Proxy(object, handler);
}

export function narrow<A extends NonNullable<any>, B extends A>(
  a: A,
  guard: (a: A) => a is B,
): B | undefined {
  return guard(a) ? a : undefined;
}
