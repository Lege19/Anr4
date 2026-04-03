import { Dialog } from "@kobalte/core/dialog";
import LoginPrompt from "@/components/LoginPrompt";
import { render } from "solid-js/web";
import { createSignal } from "solid-js";
import type { AccessToken } from "./api/auth";

// REFERENCE AS <loginPopupAuthFailureHandler-component-implementation>
const handler = () =>
  new Promise<AccessToken>((resolve) => {
    // create an element to contain the dialog
    const root = document.createElement("div");
    root.className = "dialog";
    // create a signal to control the open/close state of the dialog
    const [open, setOpen] = createSignal(true);
    // add the root to the document body
    document.body.appendChild(root);
    // mount the dialog to the root
    const dispose = render(
      () => (
        <Dialog open={open()}>
          <Dialog.Overlay class="overlay" />
          <Dialog.Content class="content">
            <div>
              <Dialog.Title>Login</Dialog.Title>
              <Dialog.Description>You need to log in again</Dialog.Description>
            </div>
            <LoginPrompt
              onSuccess={(token) => {
                // return the new token to the authentication system
                resolve(token);
                // Tell Kobalte to close the dialog.
                setOpen(false);
                const cleanup = () => {
                  // When the dialog exits, dispose and destroy the root.
                  // This makes use of Kobalte's existing behaviour to wait for animations to finish
                  dispose();
                  document.body.removeChild(root);
                };
                root.addEventListener("animationend", cleanup);
                root.addEventListener("animationcancel", cleanup);
              }}
            />
          </Dialog.Content>
        </Dialog>
      ),
      root,
    );
  });

export default handler;
