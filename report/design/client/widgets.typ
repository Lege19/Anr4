#import "primitives.typ": panel, button as prim_button, stdpad, stackh

#let input(body, ..args) = panel(text(gray.darken(50%), emph(body)), height: auto, ..args)
#let button(target, body, align_: center + horizon, ..args) = panel(align(align_, prim_button(target, body)), ..args)

#let slider_switch(..options, selected: 0, shrink: false) = {
  let tshrink = if shrink { auto } else { 100% }
  rect(
    radius: 100em,
    width: tshrink,
    inset: 0pt,
    grid(
      columns: (if shrink { auto } else { 1fr },) * options.pos().len(),
      align: center + horizon,
      ..options
        .pos()
        .enumerate()
        .map(((index, option)) => if index == selected {
          rect(
            radius: 100em,
            stroke: 1pt,
            fill: gray.lighten(50%),
            width: tshrink,
            option,
          )
        } else {
          rect(stroke: none, width: tshrink, option)
        }),
    ),
  )
}

#let scrollbar(height: 100%) = rect(
  radius: 100em,
  height: 100%,
  width: 0.5em,
  inset: 0.1em,
  fill: gray,
  rect(radius: 100em, width: 100%, height: 30%, fill: black),
)
#let scrollframe(body, dy: 0pt, height: 100%) = stackh(
  (1fr, auto),
  height: height,
  // These strange nested blocks allow for clipping the content, without making the stoke appear half width
  block(
    width: 100%,
    height: 100%,
    inset: -1pt,
    block(width: 100%, height: 100%, inset: 1pt, clip: true, move(body, dy: dy)),
  ),
  scrollbar(height: height),
)

#let checkbox(checked, body) = {
  if checked { "●" } else { "○" }
  h(0.5em)
  body
  linebreak()
}

#let dropdown(default) = panel(
  height: auto,
  align(
    left,
    {
      emph(default)
      [ ▼]
    },
  ),
)
