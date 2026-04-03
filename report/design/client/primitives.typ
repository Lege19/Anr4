#let stdpad = 5pt

#let panel(width: 100%, height: 100%, ..args, body) = rect(width: width, height: height, inset: stdpad, ..args, body)

#let stackv(rows, width: 100%, ..body) = grid(columns: width, gutter: stdpad, rows: rows, ..body)
#let stackh(columns, height: 100%, ..body) = grid(rows: height, gutter: stdpad, columns: columns, ..body)

// Register a page title to be findable with page_title
// And for references to the provided label to go to the page this ends up on
#let register_page(title, label) = [#meta(title)#label]

// Logical page as displayed in the document and PDF reader
// Requires context
#let logical_page(target) = counter(page).at(target).first()
// Physical location that can be used in links
// Requires context
#let page_location(target) = (page: locate(target).page(), x: 0pt, y: 0pt)

// Query the title of the page associated with this label
#let page_title(target) = context query(target).first().value

// A hyperlinked reference with a displayed page number
#let page_ref(target) = context link(page_location(target), [Page ] + str(logical_page(target)))

#let placeholder-fill = tiling(spacing: (3pt, 3pt), circle(fill: gray.lighten(80%), radius: 2pt))
#let placeholder = (fill: placeholder-fill, stroke: 1pt)

#let dedup-footnote(label, body) = context {
  let matches = query(selector(label).before(inclusive: false, here()))
  if matches == () {
    [#footnote(body)#label]
  } else {
    // for some reason using ref here creates layout conflicts, but this looks identical so I'm going with it.
    matches.first()
  }
}

#let button(target, body) = context {
  link(
    page_location(target),
    body,
  )
  dedup-footnote(label(str(target) + str(here().page()) + "footnote"))[#page_title(target). #page_ref(target)]
}
