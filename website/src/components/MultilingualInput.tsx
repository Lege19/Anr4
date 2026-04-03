import { TextField } from "@kobalte/core/text-field";

type DeadKey = "/" | "~" | "(" | ":" | "\\" | "^";

const DEAD_KEY_LOOKUP: Record<DeadKey, Record<string, string> | string> = {
  "/": "́",
  ":": "̈",
  "\\": "̀",
  "^": "̂",
  "~": "̃",
  "(": {
    "!": "¡",
    "?": "¿",
  },
} as const;

function shouldApplyDeadKey(c: string): boolean {
  return Boolean(c.match(/[a-zA-Z?!]/));
}

// REFERENCE AS <MultilingualInput-component-implementation>
function MultilingualInput(props: {
  value: string;
  setValue: (value: string) => void;
  onBeforeinput?: (e: InputEvent) => void;
}) {
  let input!: HTMLInputElement;
  let deadKey: null | DeadKey = null;
  let expectSelectionChange: boolean = false;

  return (
    <TextField.TextArea
      ref={input}
      class="multilingual-input"
      autoResize
      submitOnEnter
      autocomplete="off"
      rows={1}
      onBeforeinput={(e: InputEvent) => {
        props.onBeforeinput?.(e);
        if (e.defaultPrevented) return;

        if (e.inputType != "insertText" || e.data == null) {
          deadKey = null;
          return;
        }

        e.preventDefault();

        const sStart = input.selectionStart!;
        const sEnd = input.selectionEnd!;
        const sStartMinus1 = Math.max(sStart - 1, 0);

        const currentValue = props.value;

        const beforeInsertion = currentValue.slice(0, sStartMinus1);
        let insertion = currentValue.slice(sStartMinus1, sEnd);
        const afterInsertion = currentValue.slice(sEnd);

        for (const char of e.data) {
          if (char in DEAD_KEY_LOOKUP) {
            deadKey = char as DeadKey;
            insertion += char;
          } else if (
            deadKey &&
            shouldApplyDeadKey(char) &&
            insertion.length > 0 &&
            insertion[insertion.length - 1] === deadKey
          ) {
            const lookup = DEAD_KEY_LOOKUP[deadKey];
            if (typeof lookup === "string") {
              insertion = insertion.slice(0, insertion.length - 1);
              insertion += char;
              insertion += lookup;
            } else if (char in lookup) {
              insertion = insertion.slice(0, insertion.length - 1);
              insertion += lookup[char];
            } else {
              insertion += char;
            }
            deadKey = null;
          } else {
            insertion += char;
            deadKey = null;
          }
        }
        props.setValue(beforeInsertion + insertion + afterInsertion);

        expectSelectionChange = true;

        const newSStart = insertion.length + sStartMinus1;
        input.selectionStart = newSStart;
        input.selectionEnd = newSStart;
      }}
      on:selectionchange={() => {
        if (expectSelectionChange) {
          expectSelectionChange = false;
          return;
        }
        deadKey = null;
      }}
    />
  );
}

export default MultilingualInput;
