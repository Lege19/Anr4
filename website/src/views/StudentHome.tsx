import {
  For,
  createSignal,
  Switch,
  Match,
  Suspense,
  createRenderEffect,
} from "solid-js";
import { type Course, type RowId, type Topic } from "@/api/types";
import { SegmentedControl } from "@kobalte/core/segmented-control";
import Trajectory from "@/components/Trajectory";
import Leaderboard from "@/components/Leaderboard";
import { Dialog } from "@kobalte/core/dialog";
import { Button } from "@kobalte/core/button";
import type { Duration } from "date-fns";
import { World, type TableView } from "@/api/world";
import Loading from "@/components/Loading";
import { narrow } from "@/util";
import { createAsync, useNavigate } from "@solidjs/router";
import { Combobox } from "@kobalte/core/combobox";

// REFERENCE AS <TopicSelector-component-implementation>
function TopicSelector(props: {
  topics: TableView<Topic>;
  selection: RowId[];
  setSelection: (newSelection: RowId[]) => void;
}) {
  function onKeydown(e: KeyboardEvent) {
    if (e.key === "Enter") {
      e.preventDefault();
    }
  }

  return (
    <Combobox<string>
      options={Object.keys(props.topics)}
      optionTextValue={(option) => props.topics[option]!.name}
      value={props.selection}
      onChange={props.setSelection}
      placeholder="Please select some topics"
      multiple
      removeOnBackspace={false}
      closeOnSelection={false}
      noResetInputOnBlur
      //required
      class="topic-selector"
      itemComponent={(subprops) => (
        <Combobox.Item item={subprops.item} class="topic-option">
          <Combobox.ItemLabel>
            {props.topics[subprops.item.rawValue]!.name}
          </Combobox.ItemLabel>
        </Combobox.Item>
      )}
    >
      <Combobox.Label>Topic Selector</Combobox.Label>
      <Combobox.Control>
        <Combobox.Input onkeydown={onKeydown} />
      </Combobox.Control>
      <Combobox.Listbox />

      <Combobox.HiddenSelect />
    </Combobox>
  );
}

// REFERENCE AS <CourseSelector-component-implementation>
function CourseSelector(props: {
  courses: TableView<Course>;
  selectedCourse: string | undefined;
  setSelectedCourse(value: string): void;
}) {
  function tier(course: Course) {
    if (course.tierCount === 1) return;
    const tier = World.studentInfo()?.courses[course.courseId]?.tier;
    if (tier === undefined) return undefined;
    const tierString =
      course.tierCount === 2 ? ["Foundation", "Higher"][tier] : String(tier);
    return ` - ${tierString}`;
  }
  return (
    <SegmentedControl
      value={props.selectedCourse}
      onChange={props.setSelectedCourse}
      class="segmented-control"
    >
      <SegmentedControl.Indicator class="indicator" />
      <div class="items" role="presentation">
        <For each={Object.values<Course>(props.courses)}>
          {(course) => (
            <SegmentedControl.Item class="item" value={course.courseId}>
              <SegmentedControl.ItemInput />
              <SegmentedControl.ItemLabel class="item-label">
                {course.name} {tier(course)}
              </SegmentedControl.ItemLabel>
            </SegmentedControl.Item>
          )}
        </For>
      </div>
    </SegmentedControl>
  );
}

// REFERENCE AS <StudyGoals-component-implementation>
function StudyGoals(props: { id?: string }) {
  const [state, setState] = createSignal<
    | { mode: null }
    | { mode: "time"; goal: Duration }
    | { mode: "progress"; goal: number }
  >({ mode: null });

  return (
    <Switch>
      <Match when={state().mode === null}>
        <div id={props.id} class="study-goals-container">
          <Button>Set Time Goal</Button>
          <Button>Set Progress Goal</Button>
        </div>
      </Match>
      <Match when={narrow(state(), (state) => state.mode === "time")}>
        {(state) => <div class="hover-shadow panel" />}
      </Match>
    </Switch>
  );
}

// REFERENCE AS <StudentHome-view-implementation>
function StudentHome() {
  const [selectedCourse, setSelectedCourse] = createSignal<undefined | RowId>();
  const navigate = useNavigate();

  // correct invalid state between selectedCourse and studentCourses
  createRenderEffect(() => {
    const selectedCourse_ = selectedCourse();
    const studentCourses_ = World.studentInfo()?.courses;
    if (studentCourses_ !== undefined) {
      // typescript complains that selectedCourse_ could be undefined
      // typescript is completely right
      // but the `in` operator still works perfectly well in this case.
      if (!(selectedCourse_! in studentCourses_))
        setSelectedCourse(Object.keys(studentCourses_)[0]);
    } else setSelectedCourse(undefined);
  });

  const topics = createAsync(async () => {
    const selectedCourse_ = selectedCourse();
    if (selectedCourse_ === undefined) return;
    const studentCourses_ = World.studentInfo()?.courses;
    if (studentCourses_ === undefined) return;
    const selectedCourseObject = studentCourses_[selectedCourse_];
    if (selectedCourseObject === undefined) return;
    return await World.topics.loadNeeded(
      selectedCourseObject.topics,
      selectedCourseObject.tier,
    );
  });

  const [topicSelection, setTopicSelection] = createSignal<RowId[]>([]);
  createRenderEffect(() => (topics(), setTopicSelection([])));
  const startUrl = () => {
    const params = topicSelection().map((topic) => ["topic", topic]);
    const selectedCourse_ = selectedCourse();
    if (selectedCourse_) {
      const tier =
        World.studentInfo()?.courses[selectedCourse_]?.tier?.toString();
      if (tier !== undefined) params.push(["tier", tier]);
    }
    const query = new URLSearchParams(params);
    const url = new URL("/learn", location.href);
    url.search = query.toString();
    return url;
  };
  function onSubmit(e: SubmitEvent) {
    e.preventDefault();
    if (topicSelection().length === 0) return;
    const url = startUrl();
    navigate(url.pathname + url.search);
  }

  return (
    <Suspense fallback={<Loading />}>
      <main id="student-home-view">
        <CourseSelector
          courses={World.studentInfo()?.courses ?? {}}
          selectedCourse={selectedCourse()}
          setSelectedCourse={setSelectedCourse}
        />
        <div id="top-row">
          <div id="trajectory-panel" class="hover-shadow panel">
            <Trajectory unwrapped={true} />
          </div>
          <Dialog>
            <Dialog.Trigger id="leaderboard-panel">
              <Leaderboard />
            </Dialog.Trigger>
            <Dialog.Portal>
              <div class="dialog">
                <Dialog.Overlay class="overlay" />
                <Dialog.Content class="panel content">
                  <Dialog.Title>Leaderboard</Dialog.Title>
                  <Leaderboard />
                </Dialog.Content>
              </div>
            </Dialog.Portal>
          </Dialog>
        </div>
        <form id="bottom-row" action="/learn" onSubmit={onSubmit}>
          <div class="panel" id="topic-selector-panel">
            <TopicSelector
              topics={topics() ?? {}}
              selection={topicSelection()}
              setSelection={setTopicSelection}
            />
          </div>
          <StudyGoals id="study-goals-panel" />
          <Button id="start-button" type="submit">
            Start
          </Button>
        </form>
      </main>
    </Suspense>
  );
}

export default StudentHome;
