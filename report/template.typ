#import "@preview/codly:1.3.0": codly, codly-init
#import "@preview/codly-languages:0.1.10": codly-languages

#let DEV_MODE = sys.inputs.at("DEV_MODE", default: "0") == "1"

#let TITLE = "Anr4"
#let AUTHOUR = "Lege19"

#let titlepage = page(
  footer: align(center, emph(text(black.lighten(95%))[Anr4 is an extract from my GitHub SSH ed25519 public key])),
  align(horizon + center)[
    #title()
    #parbreak()
    #text(17pt, strong(AUTHOUR))
    #parbreak()
    #text(14pt)[A-Level Computer Science NEA 2026]
  ],
)

#let ref_colour = color.rgb(0, 32, 128)

// Background colour for code
#let code_bg = luma(240)
// Text style for code
#let code_text = text.with(size: 12pt * 0.75, font: "FiraCode Nerd Font Mono")
#let code_box = box.with(
  fill: code_bg,
  inset: (x: 3pt, y: 0pt),
  outset: (y: 3pt),
  radius: 2pt,
)
#let code_block(body, ..args) = {
  set par(leading: 5.8pt)
  block(
    fill: code_bg,
    inset: 0.5em,
    radius: 2pt,
    body,
    ..args,
  )
}
#let tight_code_box = code_box.with(inset: 0pt, outset: 3pt)

#let _footer(numbering) = grid(
  columns: (1fr, 1fr, 1fr),
  align(left, TITLE), align(center, context counter(page).display(numbering)), align(right, AUTHOUR),
)

#let make_outline = {
  set page(footer: _footer("i"))
  outline(
    target: heading,
    depth: 4,
  )
}

#let darkred = red.darken(50%)
#let darkgreen = green.darken(50%)

#let bullet-pro(body) = {
  set text(darkgreen)
  [- #body]
}
#let bullet-con(body) = {
  set text(darkred)
  [- #body]
}
#let bullet-neutral(body) = [- #body]

#let db_table(entity, ..rows) = block(
  breakable: false,
  table(
    align: (x, y) => {
      if y == 0 {
        alignment.center
      } else {
        alignment.left
      }
    },
    fill: (x, y) => {
      if y == 0 {
        black
      } else {
        none
      }
    },
    stroke: (x, y) => (
      (left: 1pt + black, right: 1pt + black, top: 0.5pt + black)
        + if y != rows.pos().len() {
          (bottom: 0.5pt + black)
        } else {
          (bottom: 1pt + black)
        }
    )
    ,
    strong(text(white, entity)), ..rows.pos().map(raw.with(lang: "sqlite")),
  ),
)

#let uml-class(class, fields, methods) = {
  block(
    width: 100%,
    breakable: false,
    table(
      raw(class),
      fields.map(raw).join("\n"),
      methods.map(raw).join("\n"),
    ),
  )
}

#let test-number = counter(<test>)
#let test(objective, purpose, description, test-data, expected-result, result) = [
  #block(
    width: 100%,
    breakable: false,
    table(
      columns: 2,
      [Test Number], context test-number.get().first(),
      [Objective], objective,
      [Purpose of Test], purpose,
      [Description of Test], description,
      [Test Data], test-data,
      [Expected Result], expected-result,
      [Actual Result], result,
    ),
  ) <test>]

#let evaluation-table = table.with(columns: 4)
#let evaluation-table-row(objective, user, eval) = (
  table.cell(objective),
  table.cell(objective_quote(objective)),
  table.cell(user),
  table.cell(eval),
)

#let _warnings = state("warnings", ())
#let warn(body) = context {
  let page = counter(page).get().first()
  let location = here()
  _warnings.update(curr => {
    curr.push({
      [Warning from #context link(location)[Page #page]]
      parbreak()
      if type(body) == content { body } else { repr(body) }
    })
    curr
  })
}
#let TODO(body) = (
  warn([TODO: #body]) + [#strong(text(red)[TODO]): #body]
)
#let _warning_message = block.with(
  stroke: red,
  fill: orange.lighten(50%),
  width: 100%,
  inset: 1em,
)
#let show_warnings = (
  context _warnings.final().map(warning => _warning_message(strong("WARNING\n") + warning)).join()
)
#let warning_count = context {
  let warning_count = _warnings.final().len()
  if warning_count != 0 {
    place(
      bottom,
      _warning_message(stroke: (top: red))[Compiled with #warning_count warning#if warning_count > 1 [s]],
    )
  }
}

#let hc = align.with(center + horizon)

#let styles(body) = {
  set heading(numbering: "1.", supplement: [Section])

  show: codly-init
  codly(languages: codly-languages)

  show link: it => {
    show raw: it => box(skew(ax: -10deg, it))
    // syntax highlighting will override this, but link highlighting will not
    show raw: text.with(black)
    it
  }
  show link: set text(ref_colour)
  show ref: set text(ref_colour)
  set par(first-line-indent: 0pt)

  show outline.entry: it => {
    show link: it => {
      set text(black)
      it.body
    }
    show cite: none
    it
  }
  show raw: code_text

  let fixed_syntax(scope) = bytes(
    yaml.encode((
      name: "Fixed Scope: " + scope,
      file_extensions: (scope,),
      scope: scope,
      contexts: (main: ()),
    )),
  )

  set raw(
    syntaxes: (
      "thirdparty/RustEnhanced.sublime-syntax",
      "thirdparty/SQL.sublime-syntax",
    )
      + (
        "keyword",
        "storage.type",
        "variable.parameter",
        "storage.modifier",
        "keyword.operator",
        "support.type",
        "storage.type.rust.builtin",
        "entity.name.function",
      ).map(fixed_syntax),
    theme: "thirdparty/Tomorrow.tmTheme",
  )

  set page(footer: _footer("1"))


  show heading.where(level: 1): it => pagebreak(weak: true) + it

  body
}

#let sidenote(body) = grid(
  columns: 2,
  gutter: 1em,
  grid.cell(fill: gray.lighten(30%), h(0.5em)), grid.cell(inset: 0.5em, body),
)
