#import "@preview/fletcher:0.5.8" as fletcher: diagram, node, edge
#import fletcher.shapes: diamond

#let node = node.with(inset: 1em)
#let edge = edge.with(marks: "-|>", stroke: 1pt)
#let flowchart = diagram.with(node-stroke: 1pt)
#let start = node((0, 0), [Start], corner-radius: 100em)
#let end = node.with(extrude: (0pt, 5pt), outset: 5pt)
#let decision = node.with(shape: diamond)

