import ALink from "@/components/ALink";
import { Button } from "@kobalte/core/button";
import { TextField } from "@kobalte/core/text-field";
import {
  createSignal,
  batch,
  Index,
  Show,
  type Accessor,
  createMemo,
} from "solid-js";
import { Correctness, type MistakeType } from "@/algorithms/correctness";
import {
  LearningModel,
  Question,
  WritingQuestion,
  type LearningModelParams,
} from "@/algorithms/learningModel";
import { Toast } from "@kobalte/core/toast";
import MultilingualInput from "@/components/MultilingualInput";
import { narrow, RenderOnceShow } from "@/util";
import { useSearchParams } from "@solidjs/router";

// REFERENCE AS <MistakeHighlighter-component-implementation>
function MistakeHighlighter(props: {
  correctness: Correctness | undefined;
  onCorrect?: () => void;
}) {
  type MistakeItem = { type: MistakeType; body: string };
  type Item = MistakeItem | string;
  function renderItem(item: Accessor<Item>) {
    return (
      <Show
        when={typeof item() === "string"}
        fallback={((item) => (
          <span class={"mistake-highlight-" + item.type}>{item.body}</span>
        ))(item() as MistakeItem)}
      >
        {item() as string}
      </Show>
    );
  }
  const items: Accessor<undefined | Item[]> = () => {
    const correctness = props.correctness;
    if (correctness === undefined) return;
    const mistakes = correctness.getMistakes();
    if (mistakes == undefined) return [correctness.input];

    if (mistakes.length === 0) {
      props.onCorrect?.();
      return [correctness.input];
    }

    const input = correctness.input;
    const out = [];

    let idx = 0;
    for (const mistake of mistakes) {
      if (mistake.span[0] != idx) {
        out.push(input.slice(idx, mistake.span[0]));
      }
      out.push({
        type: mistake.type,
        body: input.slice(...mistake.span),
      });
      idx = mistake.span[1];
    }
    out.push(input.slice(idx));

    return out;
  };

  return (
    <Show when={items()}>
      {(items) => (
        <div class="mistake-highlighter">
          <Index each={items()}>{renderItem}</Index>
        </div>
      )}
    </Show>
  );
}

function DisplayQuestion(props: { question: Question }) {
  return <>{props.question.question}</>;
}

function useLearningModelParams(): LearningModelParams {
  const [params] = useSearchParams();
  const topics = params.topic;
  const topicsArray = Array.isArray(topics)
    ? topics
    : topics === undefined
      ? []
      : [topics];
  const tier = params.tier;
  const tierNumber = Array.isArray(tier)
    ? Number(tier[tier.length - 1])
    : tier === undefined
      ? null
      : Number(tier);
  return {
    topicIds: topicsArray,
    tier: tierNumber,
  };
}

const Phase = {
  // student is typing an answer to a question
  Input: "p",
  // student is correcting a previous answer (mistakes higlighted)
  Correction: "c",
  // student is shown the correct answer to a question they got wrong
  Introduce: "t",
  // code is blocked (on a promise) somewhere,
  //
  // This should almost never happen in practice
  Waiting: "w",
} as const;
type Phase = (typeof Phase)[keyof typeof Phase];
type PhaseNot<T> = Exclude<Phase, T>;
type State = { phase: Phase } & (
  | { phase: typeof Phase.Input; initial: boolean }
  | { phase: PhaseNot<typeof Phase.Input> }
) &
  (
    | { phase: PhaseNot<typeof Phase.Waiting>; question: Question }
    | { phase: typeof Phase.Waiting; question: Promise<Question> }
  );

function Learn() {
  const learningModelParams = useLearningModelParams();
  const learningModel = LearningModel(learningModelParams);

  const waitForQuestion = (): State => ({
    phase: Phase.Waiting,
    question: learningModel
      .getQuestion()
      .then(
        (question) => (
          setState({ phase: Phase.Input, question, initial: true }),
          question
        ),
      ),
  });

  // keeping the state object readonly is important
  // it prevents accidental modification of the state object,
  // which would not update the signal.
  // I could use a store here, but I think the benefit is minimal
  const [state, setState] = createSignal<Readonly<State>>(waitForQuestion());

  const [studentAnswer, setStudentAnswer] = createSignal("");

  const correctness = () => {
    const state_ = state();
    if (state_.phase === Phase.Waiting)
      throw new Error(
        "Cannot get correctness during Waiting phase, the question is not known",
      );
    return new Correctness(state_.question.correctAnswer, studentAnswer());
  };

  const question = createMemo(() =>
    narrow(state().question, (question) => question instanceof Question),
  );

  function nextQuestion() {
    batch(() => {
      setState(waitForQuestion());
      setStudentAnswer("");
    });
  }

  function onSubmit(e: SubmitEvent) {
    // prevent the form getting sent off
    e.preventDefault();

    const state_ = state();
    switch (state_.phase) {
      case Phase.Input: {
        const correctness_ = correctness();
        if (state_.initial) {
          learningModel.send(state_.question, correctness_.correctness);
        }
        if (correctness_.correctness === 1) {
          nextQuestion();
        } else if (correctness_.correctness > 0.5)
          setState({ phase: Phase.Correction, question: state_.question });
        else setState({ phase: Phase.Introduce, question: state_.question });
        break;
      }
      case Phase.Correction: {
        const correctness_ = correctness();
        if (correctness_.correctness === 1) {
          nextQuestion();
        } else {
          setState({ phase: Phase.Introduce, question: state_.question });
        }
        break;
      }
      case Phase.Introduce: {
        batch(() => {
          setState({
            phase: Phase.Input,
            initial: false,
            question: state_.question,
          });
          setStudentAnswer("");
        });

        break;
      }
    }
  }

  function onBeforeinput() {
    const state_ = state();
    if (state_.phase === Phase.Introduce) {
      batch(() => {
        setStudentAnswer("");
        setState({
          phase: Phase.Input,
          initial: false,
          question: state_.question,
        });
      });
    }
  }

  const showAnswer = createMemo(() => state().phase === Phase.Introduce);

  return (
    <>
      <main id="learn-view">
        <ALink href="/" id="home-button">
          Home
        </ALink>
        <form onSubmit={onSubmit}>
          <TextField
            class="question-container"
            value={studentAnswer()}
            onChange={setStudentAnswer}
            validationState={showAnswer() ? "invalid" : "valid"}
          >
            <div class="panel">
              <TextField.Label class="question-label">
                <RenderOnceShow when={question()}>
                  {(question) => <DisplayQuestion question={question()} />}
                </RenderOnceShow>
              </TextField.Label>
            </div>
            <div class="answer-row">
              <div class="panel">
                <div style={{ position: "relative" }}>
                  <Show when={state().phase === Phase.Correction}>
                    <MistakeHighlighter correctness={correctness()} />
                  </Show>
                  <MultilingualInput
                    value={studentAnswer()}
                    setValue={setStudentAnswer}
                    onBeforeinput={onBeforeinput}
                  />
                </div>
              </div>
              <Button type="submit">Submit</Button>
            </div>
            <TextField.ErrorMessage class="correct-answer">
              {question()?.correctAnswer}
            </TextField.ErrorMessage>
          </TextField>
        </form>
        <div id="feedback-settings" />
      </main>
      <Toast.Region class="toast-region">
        <Toast.List class="toast-list" />
      </Toast.Region>
    </>
  );
}

export default Learn;
