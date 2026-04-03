import { AccessToken } from "@/api/auth";
import { Button } from "@kobalte/core/button";
import { TextField } from "@kobalte/core/text-field";
import { createSignal } from "solid-js";

// REFERENCE AS <LoginPrompt-component-implementation>
/**
 * A login prompt.
 *
 * @param onSuccess - A callback to run when the login prompt recieves a successful login
 */
function LoginPrompt(props: { onSuccess: (token: AccessToken) => void }) {
  const [incorrectLogin, setIncorrectLogin] = createSignal(false);

  async function submit(e: SubmitEvent) {
    e.preventDefault();
    const res = await fetch("/api/login", {
      body: new URLSearchParams(
        new FormData(e.target as HTMLFormElement) as any,
      ),
      method: "post",
    });
    if (res.status !== 200) {
      setIncorrectLogin(true);
    } else {
      const token = new AccessToken(await res.text());
      props.onSuccess(token);
    }
  }
  return (
    <form on:submit={submit} id="login-form">
      <TextField name="email">
        <TextField.Label>Email</TextField.Label>
        <TextField.Input type="email" required />
      </TextField>
      <TextField
        name="password"
        validationState={incorrectLogin() ? "invalid" : "valid"}
      >
        <TextField.Label>Password</TextField.Label>
        <TextField.Input type="password" required />
        <TextField.ErrorMessage>
          Incorrect Email or Password
        </TextField.ErrorMessage>
      </TextField>
      <Button type="submit">Log In</Button>
    </form>
  );
}
export default LoginPrompt;
