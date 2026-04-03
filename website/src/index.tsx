/* @refresh reload */
import { render } from "solid-js/web";
import "./styles/index.scss";
import { Router, Route } from "@solidjs/router";
import loginPopupAuthFailureHandler from "./loginPopupAuthFailureHandler";
import { lazy } from "solid-js";

// "Don't worry about wrapping it with a isDev guard, the Overlay takes care of that for you. It should be excluded from production builds automatically."
import { attachDevtoolsOverlay } from "@solid-devtools/overlay";
import { Auth } from "./api/auth";
//attachDevtoolsOverlay();

const root = document.getElementById("root")!;

Auth.addAuthFailureHandler(loginPopupAuthFailureHandler);

render(() => {
  return (
    <>
      <Router>
        <Route path="/" component={lazy(() => import("@/views/Home"))} />
        <Route path="/login" component={lazy(() => import("@/views/Login"))} />
        <Route path="/learn" component={lazy(() => import("@/views/Learn"))} />
        <Route
          path="/debug/correctness"
          component={lazy(() => import("@/views/DebugCorrectness"))}
        />
      </Router>
    </>
  );
}, root);
