#import "../../template.typ": TODO, sidenote
#import "@preview/codly:1.3.0"
#set heading(offset: 3)
#set list(marker: [–])

The appearance of most of these was already described in the wireframes section,
so this section is more about what they _do_ than what they look like.

= `ALink`
Implemented in #link(<ALink-component-implementation>)[`components/ALink.tsx`]

Integrates #link("https://kobalte.dev/docs/core/components/link")[Kobalte Link] component
and #link("https://docs.solidjs.com/solid-router/reference/components/a")[Solid Router A] component

Kobalte has a _semantic_ `Link` component which provides accessibility information.\
Solid Router has a _functional_ `A` component which provides integration with the Single Page `Router` from Solid Router.

/ Attributes: The same as Solid Router `A`

= `Leaderboard`
Implemented in #link(<Leaderboard-component-implementation>)[`components/Leaderboard.tsx`]

Since the student leaderboard appears in multiple places in the UI,
it should be extracted to a separate component.

/ Attributes:
  - ```ts studentId: RowId | undefined```
  - ```ts scope: {cohortId: RowId} | {classId: RowId}```

= `Loading`
Implemented in #link(<Loading-component-implementation>)[`components/Loading.tsx`]
The message/spinner to display to indicate something is loading.

#sidenote[
  Since this really wasn't worth spending time on,
  it is just text that says "Loading"
]

= `LoginPrompt`
Implemented in #link(<LoginPrompt-component-implementation>)[`components/LoginPrompt.tsx`]

This is the login prompt that will be used in the login page and by the login popup.

It will display an HTML form, and make the neccessary requests to the server for each login attempt.

If the user is already logged in, it will display a message saying they are already logged in.

On unsuccessful login, it will display the usual "email or password is incorrect" message.

Since the login page and the login popup will handle a successful login differently,
this componenet will return the access token it received from the server instead of interfacing with the authentication system directly to set the new access token.

/ Attributes: A callback function to be called with the new access token if the login is successful.

= `MultilingualInput`
Implemented in #link(<MultilingualInput-component-implementation>)[`components/MultilingualInput.tsx`]

This will be the component responsible for typing characters that are not otherwise easy for students using UK QWERTY to type.

This will wrap a Kobalte `TextField.TextArea` component with a complex event handler `onbeforeinput`.

/ Attributes:
  A callback function to be called before the rest of the `onbeforeinput` event handler.
  If this callback function calls `preventDefault` on the `InputEvent` event, the rest of the `onbeforeinput` event handler does not run.

#sidenote[
  I didn't anticipate how difficult it would be to correctly handle this in all situations,
  including when the student moves the cursor around or inserts characters in the middle of the text area.
  As a result of this, my initial design did not include the algrithm for how this was done.

  Here is the final algorithm in pseudocode:
  #codly.local(
    lang-format: none,
    ```python
    onbeforeinput(input_event):
        callback(input_event)
        if input_event.was_cancelled:
            return

        if input_event.type != 'insertText'
           or input_event.inserted_text is null:
            deadKey = null
            return

        input_event.prevent_default()

        s_start = textarea.selection_start
        s_end = textarea.selectionEnd
        s_start_minus_1 = max(s_start - 1, 0)

        current_value = textarea.value

        before_insertion = current_value[0:s_start_minus_1]
        insertion = current_value[s_start_minus_1:s_end]
        after_insertion = current_value[s_end:]

        for char in input_event.inserted_text:
            if char in DEAD_KEY_LOOKUP:
                dead_key = char
                insertion += char
            else if dead_key is not null
                    and should_apply_dead_key(char)
                    and insertion.length > 0
                    and insertion[insertion.length - 1] == dead_key:
                lookup = DEAD_KEY_LOOKUP[dead_key]
                if lookup is a string:
                    insertion = insertion[0:insertion.length - 1]
                    insertion += char
                    insertion += lookup
                else if char in lookup:
                    insertion = insertion[0:insertion.length - 1]
                    insertion += lookup[char]
                else:
                    insertion += char

                dead_key = null;
            else:
                insertion += char;
                dead_key = null;

        textarea.value = before_insertion + insertion + after_insertion

        new_s_start = insertion.length + s_start_minus_1
        textarea.selection_end = new_s_start
        textarea.selection_end = new_s_start
    ```,
  )
  Where `DEAD_KEY_LOOKUP` is a lookup table:
  #codly.local(
    lang-format: none,
    number-format: none,
    ```js
    {
      "/": COMBINING_ACCENT,
      ":": COMBINING_DIAERESIS,
      "\\": COMBINING_GRAVE_ACCENT,
      "^": COMBINING_CIRCUMFLEX,
      "~": COMBINING_TILDE,
      "(": {
        "!": "¡",
        "?": "¿",
      }
    }
    ```,
  )
  See also: #link("https://en.wikipedia.org/wiki/Combining_Diacritical_Marks")[Wikipedia on Combining Diacritical Marks]

  This isn't even enough either though, because it also needs to handle when the student moves the cursor around,
  so I actually also needed another event handler for `onselectionchange`.
]

= `Trajectory`
Implemented in #link(<Trajectory-component-implementation>)[`components/Trajectory.tsx`]

This component shall be responsible for showing the student progress graphs.

#sidenote[
  This was quite low priority so I didn't flesh out the design,
  and I was right:

  I ran out of time to implement this.

  Realistically this was only ever going to be a stub to take up the space the real content it should display would take up.
]

= `MistakeHighlighter`
Implemented in #link(<MistakeHighlighter-component-implementation>)[`views/Learn.tsx`]
This will highlight mistakes in the student's answer.

Note that this is not responsible for calculating the information it is displaying.

/ Attributes:
  - ```ts correctness: Correctness | undefined```
  - ```ts onCorrect(): void```

`correctness` holds the information to display
`onCorrect` is a callback function to call if there are no mistakes.

= `TopicSelector`
Implemented in #link(<TopicSelector-component-implementation>)[`views/Learn.tsx`]

This will be used on the student home page for selecting the topics which the student would like to study.

It should display a scrollable list of the topics,
which can each be toggled between selected and not selected.

It should also provide search functionality for finding a particular topic by name.

/ Attributes:
  - ```ts topics: Record<string, Topic>```
  - ```ts selection: RowId[]```
  - ```ts setSelection(newSelection: RowId[]): void```
#sidenote[
  Don't worry about `selection` and `setSelection` too much,
  this is just the SolidJS way of reporting the user's selection to the parent component.
]

= `CourseSelector`
Implemented in #link(<CourseSelector-component-implementation>)[`views/Learn.tsx`]

This will be used on the student home page for selecting which course the student wants to study for.

Since there shouldn't be many of these, being searchable and scrollable are not as important as for the topic selector.

/ Attributes:
  - ```ts courses: Record<string, Course>```
  - ```ts selectedCourse: string | undefined```
  - ```ts setSelectedCourse(value: string): void```

= `StudyGoals`
Implemented in #link(<StudyGoals-component-implementation>)[`views/Learn.tsx`]

= `loginPopupAuthFailureHandler`
Implemented in #link(<loginPopupAuthFailureHandler-component-implementation>)[`loginPopupAuthFailureHandler.tsx`]

This won't be a normal component.
In SolidJS, most components come as functions which are called once.
This component is a function which is called to open the pop-up
(which renders the pop-up from scratch each time)
and returns a promise which eventually resolves to an access token if the user logged in using the pop-up.

This should display the `LoginPrompt` component in a modal pop-up which prevents the user from interacting with the rest of the page until they have logged in.

Making this work will require some trickery
