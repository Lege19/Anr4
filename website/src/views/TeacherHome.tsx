import { World } from "@/api/world";
import Loading from "@/components/Loading";
import { Suspense } from "solid-js";

function TeacherHome() {
  const teacherName = () => {
    const teacherInfo_ = World.teacherInfo();
    if (teacherInfo_ === undefined) return;
    return `${teacherInfo_.forename} ${teacherInfo_.surname}`;
  };
  return (
    <>
      <Suspense fallback={<Loading />}>
        <h2>Teacher Home Page</h2>
        <p>Signed in as {teacherName()}</p>
      </Suspense>
    </>
  );
}
export default TeacherHome;
