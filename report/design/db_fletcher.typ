#import "@preview/fletcher:0.5.8": diagram, node, edge
#let erd = diagram.with(node-stroke: 1pt, edge-corner-radius: 5pt)
#let entity(position, name, ..args) = node(position, inset: 1em, name: label(name + "-entity"), ..args, name)

// I started making a wrapper to get different kinds of ERD edge
// But fletcher already has it covered
// n == many
// n! == one or more
// n? == zero or more
// 1 == one
// 1? == zero or one
// 1! == exactly one
#let relationship(..args) = edge(
  ..args.pos().slice(0, -1).map(it => if type(it) == str { label(it + "-entity") } else { it }),
  args.pos().at(-1),
  ..args.named(),
  stroke: 1pt,
)

#let ghost_entity = entity.with(stroke: (dash: "dashed"))
