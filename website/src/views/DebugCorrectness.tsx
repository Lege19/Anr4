import { Correctness } from "@/algorithms/correctness";
import { TextField } from "@kobalte/core/text-field";
import { createMemo, createSignal } from "solid-js";

function Debug() {
  const [a, setA] = createSignal("");
  const [b, setB] = createSignal("");

  const correctness = createMemo(() => new Correctness(a(), b()));

  return (
    <>
      <TextField value={a()} onChange={setA}>
        <TextField.Label>a</TextField.Label>
        <TextField.Input />
      </TextField>
      <TextField value={b()} onChange={setB}>
        <TextField.Label>b</TextField.Label>
        <TextField.Input />
      </TextField>
      {correctness().debugDisplay()}
    </>
  );
}

export default Debug;
