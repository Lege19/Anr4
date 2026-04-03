import { AccessToken, Auth } from "@/api/auth";
import LoginPromt from "@/components/LoginPrompt";
import { useNavigate } from "@solidjs/router";
import { Show } from "solid-js";

function Login() {
  const navigate = useNavigate();
  return (
    <Show when={!Auth.accessToken()} fallback={<>You've already logged in</>}>
      <LoginPromt
        onSuccess={(token: AccessToken) => {
          Auth.logIn(token);
          navigate("/");
        }}
      />
    </Show>
  );
}
export default Login;
