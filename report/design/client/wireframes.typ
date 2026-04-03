#import "primitives.typ": page_location, page_ref, page_title, panel

#let wireframe(title, label, body, notes: [], border: true, variable_page_size: false) = {
  let body = align(center + horizon, body)
  page(
    {
      if border {
        panel(height: if variable_page_size { auto } else { (595.28pt - 2.5cm * 2) / 16 * 9 }, body)
      } else { body }
      [#metadata(title)#label]
      notes
    },
    margin: 2.5cm,
    height: auto,
    header: align(center, title) + counter(footnote).update(0),
  )
}

// For use as a flowchart node
#let load_page(target) = {
  [Load ]
  context {
    link(
      page_location(target),
      page_title(target),
    )
  }
  footnote(page_ref(target))
}
