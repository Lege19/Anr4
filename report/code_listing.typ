#set heading(offset: 1)
#set par(spacing: 1em)

#show regex("REFERENCE AS <(.*)>"): match => [#match#label(match.text.match(regex("<(.*)>")).captures.first())]

#let current-src-file = state("current-src-file", none)

#let print_file(path, name) = {
  current-src-file.update(old => name)
  [#heading(name, depth: 2)#label(name)]
  raw(
    read(path),
    lang: path.split(".").last(),
    block: true,
  )
}

#let src-file-ref(name) = link(label(name), context raw(current-src-file.at(label(name))))

#let files = read("manifest").split("\n")

= Server
#print_file("../Cargo.toml", "Cargo.toml")

#print_file("../migrations/20250809091053_initial.sql", "initialise.sql")<database-schema-ddl>

#for file in files {
  if file.starts-with("./src") {
    print_file("../" + file, file.split("src/").last())
  }
}

= Client
#print_file("../website/package.json", "package.json")
#print_file("../website/tsconfig.app.json", "tsconfig.json")
#print_file("../website/index.html", "index.html")

#for file in files {
  if file.ends-with(".d.ts") {
    continue
  }
  if file.starts-with("./website/src") {
    print_file("../" + file, file.split("src/").last())
  }
}
