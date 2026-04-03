// #set heading(offset: 3)

#import "@preview/treet:1.0.0": tree-list
#import "../../template.typ": code_block, code_box
#import "@preview/cmarker:0.1.7"
#import "rust_item_renderer.typ": get_item, item_name, item_signature, path_to_doc_url

#import "@preview/codly:1.3.0": codly-disable

#let data = json("../../../target/doc/vocab.json")

// Since I'm now modifying the input data, I'm first checking I'm not
// overwriting anything
#assert("kind" not in data.index.values().fold((), (a, b) => a + b.keys()).dedup())
#for (key, value) in data.index {
  let inner = data.index.at(key).inner
  let kind = inner.keys()
  assert.eq(kind.len(), 1)
  kind = kind.first()
  data.index.at(key).inner = inner.at(kind)
  data.index.at(key).kind = kind
}

#let root_urls = (
  toml("../../../Cargo.lock")
    .package
    .map(it => {
      (
        it.name,
        "https://docs.rs/" + it.name + "/" + it.version + "/",
      )
    })
    .to-dict()
)

#let ctx = (data: data, root_urls: root_urls)
#let get_item = get_item.with(ctx)
#let item_signature = item_signature.with(ctx)
#let path_to_doc_url = path_to_doc_url.with(ctx)

#let root = {
  let tmp = data
    .index
    .values()
    .filter(it => (
      it.kind == "module" and it.inner.is_crate == true
    ))
  assert.eq(tmp.len(), 1, message: "Expecting only one item")
  tmp.first()
}

#let apply_links(body, links) = {
  for (link, id) in links {
    let url = path_to_doc_url(id)
    if type(url) == label {
      body = body.replace("[" + link + "]", "[" + link + "](#" + str(url) + ")")
    } else {
      body = body.replace("[" + link + "]", "[" + link + "](" + url + ")")
    }
  }
  body
}
#let render_doc_comment(body, links) = cmarker.render(apply_links(body, links))

#let module-tree(module, path: ()) = {
  for item in module.inner.items.map(get_item) {
    if item.kind != "use" {
      path.push(item.name)
    } else {
      path.push(item.inner.name)
    }
    list.item({
      let name = item_name(item)
      name.children.slice(0, -1).join()
      link(label(path.join("::") + "__" + item.kind), name.children.last())
      if item.kind == "module" {
        module-tree(item, path: path)
      }
    })
    let _ = path.pop()
  }
}

#let render_item(item, path: (), show_name: true) = {
  if item.kind != "use" {
    path.push(item.name)
  } else {
    path.push(item.inner.name)
  }
  let label = label(path.join("::") + "__" + item.kind)
  if show_name {
    [
      #heading(
        raw(path.join("::"), lang: none),
        outlined: false,
        numbering: none,
      )
      #label
    ]
  } else {
    [#[]#label]
  }

  item_signature(item)
  if item.docs != none {
    render_doc_comment(item.docs, item.links)
    linebreak()
  }

  if item.kind == "module" {
    for item in item.inner.items {
      render_item(get_item(item), path: path)
    }
  } else if item.kind == "impl" and "trait" not in item.inner {
    for item in item.inner.items {
      list.item(render_item(get_item(item), path: path))
    }
  } else if item.kind == "struct" {
    if "tuple" in item.inner.kind { [Elements:\ ] } else { [Fields:\ ] }
    for item in if "tuple" in item.inner.kind {
      item.inner.kind.tuple
    } else {
      item.inner.kind.plain.fields
    } {
      list.item(render_item(get_item(item), path: path, show_name: false))
    }
  } else if item.kind == "enum" {
    [Variants:\ ]
    for item in item.inner.variants {
      list.item(render_item(get_item(item), path: path, show_name: false))
    }
  } else if item.kind == "variant" {
    if item.inner.kind != "plain" {
      if "tuple" in item.inner.kind { [Elements:\ ] } else { [Fields:\ ] }
      for item in if "tuple" in item.inner.kind {
        item.inner.kind.tuple
      } else {
        item.inner.kind.struct.fields
      } {
        list.item(render_item(get_item(item), path: path, show_name: false))
      }
    }
  }

  if item.kind in ("struct", "enum") {
    let impls = item.inner.impls.map(get_item)
    let non_trait_impls = ()
    let trait_impls = ()
    for item in impls {
      if item.inner.trait == none {
        non_trait_impls.push(item)
      } else {
        trait_impls.push(item)
      }
    }
    if trait_impls != () {
      [Trait Implementations:\ ]
      for item in trait_impls {
        if (
          item.inner.blanket_impl == none
            and not item.inner.is_synthetic
            and item.inner.trait.path
              not in (
                "Debug",
                "Display",
                "Clone",
              )
        ) {
          list.item(item_signature(item))
        }
      }
    }
    if non_trait_impls != () {
      [Associated Items:\ ]
      for item in non_trait_impls {
        for item in item.inner.items {
          list.item(render_item(get_item(item), show_name: false))
        }
      }
    }
  }

  let _ = path.pop()
}


= Items <server-item-tree>

#let format_marker(marker) = (
  (
    h(0.5em)
      + box(
        move(
          dy: 1pt,
          text(
            font: "FiraCode Nerd Font",
            black,
            marker,
          ),
        ),
      )
  )
    + h(0.4em)
)
#{
  item_name(root)
  linebreak()
  tree-list(
    module-tree(root),
    marker: format_marker("├─"),
    indent: format_marker("│"),
    last-marker: format_marker("└─"),
  )
}

#set page(
  header: align(
    center,
    emph(
      link(
        <server-item-tree>,
        text(gray.darken(30%))[Return to item tree],
      ),
    ),
  )
    + line(length: 100%, stroke: 0.8pt + gray),
)

#for item in root.inner.items {
  render_item(get_item(item))
}
#set page(header: none)

