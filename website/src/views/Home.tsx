import ALink from "@/components/ALink";
import { Match, Show, Switch } from "solid-js";
import StudentHome from "./StudentHome";
import TeacherHome from "./TeacherHome";
import { Auth } from "@/api/auth";

function Home() {
  return (
    <Show
      when={Auth.accessToken()}
      fallback={<ALink href="/login">Log In</ALink>}
    >
      {(accessToken) => (
        <Switch>
          <Match when={accessToken().claims.kind === "Student"}>
            <StudentHome />
          </Match>
          <Match when={accessToken().claims.kind === "Teacher"}>
            <TeacherHome />
          </Match>
        </Switch>
      )}
    </Show>
  );
}
export default Home;
