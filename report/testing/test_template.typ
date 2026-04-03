#import "../template.typ": DEV_MODE, darkgreen, darkred, warn

#let passing = text(darkgreen)[*Passing*]
#let failing = text(darkred)[*Failing*]
#let normal-data = [_ND_]
#let boundary-data = [_BD_]
#let erroneous-data = [_ED_]
#let VIDEO-URL = "https://youtu.be/esUfYocBVKM"

#let _current_repeat = counter("__test-current-repeat")

#let test_type = state("test-type")

#let test_id(type) = counter("test-id__" + type)

#let test_table(type, tests) = {
  test_type.update(_ => type)
  table(
    columns: 6,
    table.header(
      repeat: true,
      [*Test No.*], [*Name*], [], [*Data*], [*Expected Result*], [*Results*],
    ),
    ..tests,
  )
  test_id(type).update((..values) => (values.pos().at(0) + 1, 0))
}

/*
 * #type test {
 *   name: content,
 *   data_category: "normal" | "boundary" | "erroneous" | none,
 *   input_data: content,
 *   expected_result: content,
 *   rows: ({
 *    kind: "run",
 *    result: content,
 *   } | {
 *     kind: "fix",
 *     description: content,
 *   })[]
 * }
 */

#let _run(test, run, repeat: []) = (
  table.cell({
    context test_type.get() + context test_id(test_type.get()).display() + repeat
  }),
  table.cell(test.name),
  table.cell(if test.data_category != none {
    (normal: normal-data, boundary: boundary-data, erroneous: erroneous-data).at(test.data_category)
  }),
  table.cell(test.input_data),
  table.cell(test.expected_result),
  table.cell(run.result),
)

#let test(..args) = {
  let test = if (args.pos().len() == 1 and args.named().keys().len() == 0) {
    args.pos().at(0)
  } else if (args.pos().len() == 0) { args.named() } else { panic("unreachable") }
  let cells = if ("rows" in test) {
    let repeat_count = test.rows.filter(row => row.kind == "run").len()
    test
      .rows
      .map(row => if row.kind == "run" {
        _run(test, row, repeat: if repeat_count > 1 {
          _current_repeat.step()
          context _current_repeat.display("a")
        } else [])
      } else if row.kind == "fix" {
        table.cell(colspan: 6, row.description)
      } else {
        panic("unreachable")
      })
      .flatten()
  } else if ("result" in test) { _run(test, (kind: "run", result: test.result)) } else { panic("unreachable") }

  let first_cell = cells.at(0)
  let fields = first_cell.fields()
  let _ = fields.remove("body")
  cells.at(0) = table.cell(
    ..fields,
    context test_id(test_type.get()).step(level: 2) + _current_repeat.update(0) + first_cell.body,
  )
  cells
}


#let sqlite_table(data, pretty: false) = {
  let headers = data.at(0).keys()
  if (pretty) {
    table(
      columns: headers.len(),
      table.header(..headers.map(strong)),
      ..data
        .map(x => x.values())
        .flatten()
        .map(x => if type(x) == float {
          if x > 10000000 {
            (
              datetime(year: 1970, day: 1, month: 1, hour: 0, minute: 0, second: 0) + duration(seconds: int(x))
            ).display()
          } else if x > 60 * 24 * 24 * 0.1 {
            str(calc.round(duration(seconds: int(x)).days(), digits: 4)) + " Days"
          } else { x }
        } else { x })
        .map(x => if type(x) in (int, float, decimal) { calc.round(x, digits: 4) } else { x })
        .map(x => [#x])
    )
  } else {
    table(
      columns: headers.len(),
      table.header(..headers.map(strong)),
      ..data.map(x => x.values()).flatten().map(x => [#x])
    )
  }
}

#let _video-data = {
  let raw-data = xml("media/video/NEA.mlt")
  let mlt = raw-data.find(elem => elem.tag == "mlt")
  let chains = mlt
    .children
    .filter(child => type(child) == dictionary and child.tag == "chain")
    .map(child => (
      child.attrs.id,
      child
        .children
        .find(elem => type(elem) == dictionary and elem.tag == "property" and elem.attrs.name == "resource")
        .children
        .first(),
    ))
    .to-dict()
  let playlist = mlt.children.find(elem => (
    type(elem) == dictionary and "id" in elem.attrs and elem.attrs.id == "playlist0"
  ))
  let time = 0
  let clip-times = (:)

  let toseconds(time) = {
    let (hours, minutes, seconds) = time.split(":")
    (int(hours) * 60 + int(minutes)) * 60 + float(seconds)
  }

  for item in playlist.children {
    if type(item) != dictionary { continue }
    if item.tag == "property" { continue }
    if item.tag == "filter" { continue }
    if item.tag != "entry" { panic("unrecognised tag") }
    let chain = chains.at(item.attrs.producer)
    clip-times.insert(chain, time)
    time += toseconds(item.attrs.out) - toseconds(item.attrs.in)
  }
  clip-times
}

#let VIDEO-DESCRIPTION = {
  for (clip, time) in _video-data.pairs() {
    let minutes = calc.trunc(time / 60)
    let seconds = str(calc.trunc(calc.rem(time, 60)))
    if seconds.len() == 1 {
      seconds = "0" + seconds
    }
    [#clip.trim(".mp4", at: end, repeat: false): #minutes:#seconds\ ]
  }
}


#let format-time(hours, minutes, seconds) = {
  let hours = str(hours)
  if hours.len() < 2 {
    hours = "0" + hours
  }
  let minutes = str(minutes)
  if minutes.len() < 2 {
    minutes = "0" + minutes
  }
  let seconds = "00" + str(seconds)
  if not "." in seconds {
    seconds += "."
  }
  seconds += "0000"
  let decimal-position = seconds.match(".").start
  seconds = seconds.slice(decimal-position - 2, decimal-position + 3)
  [#hours:#minutes:#seconds]
}

#let timestamp(file) = {
  if file not in _video-data {
    return warn[Unrecognised video clip #file] + [UNKNOWN TIMESTAMP]
  }
  let total-seconds = _video-data.at(file)
  let minutes = calc.trunc(total-seconds / 60)
  let hours = calc.trunc(minutes / 60)
  minutes = calc.rem(minutes, 60)
  let seconds = calc.rem(total-seconds, 60)
  link(VIDEO-URL + "&t=" + str(total-seconds) + "s", format-time(hours, minutes, seconds))
}
