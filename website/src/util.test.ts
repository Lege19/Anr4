import { expect, test } from "vitest";
import { viewProxy } from "./util";

const table = {
  0: "table[0]",
  1: "table[1]",
  a: "table.a",
  b: "table.b",
};
const view = viewProxy(table, [0, "a"]) as any;

test("Test view access", () => {
  expect(view[0]).toBe("table[0]");
  expect(view[1]).toBeUndefined();
  expect(view[2]).toBeUndefined();
  expect(view.a).toBe("table.a");
  expect(view.b).toBeUndefined();
  expect(view.c).toBeUndefined();

  try {
    view[0] = "table[1]";
    expect.unreachable();
  } catch (error) {
    expect(error).toBeInstanceOf(TypeError);
  }
  try {
    view.a = "table.b";
    expect.unreachable();
  } catch (error) {
    expect(error).toBeInstanceOf(TypeError);
  }
  try {
    view[1] = "table[0]";
    expect.unreachable();
  } catch (error) {
    expect(error).toBeInstanceOf(TypeError);
  }
  try {
    view[2] = "table[0]";
    expect.unreachable();
  } catch (error) {
    expect(error).toBeInstanceOf(TypeError);
  }
});

test("Test view entries", () => {
  expect(Object.keys(view)).toEqual(["0", "a"]);
  expect(Object.values(view)).toEqual(["table[0]", "table.a"]);
  expect(Object.entries(view)).toEqual([
    ["0", "table[0]"],
    ["a", "table.a"],
  ]);
});

test("Test view has", () => {
  expect(0 in view).toBe(true);
  expect(1 in view).toBe(false);
  expect("a" in view).toBe(true);
  expect("b" in view).toBe(false);
});
