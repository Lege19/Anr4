#import "../../template.typ": code_block, code_box, warn

#let stub(..a) = warn([STUB]) + [STUB]

#let get_item(ctx, id) = ctx.data.index.at(str(id))

#let _indent(depth) = raw("\t" * depth)
#let _frag(text) = raw(text + " ", lang: "keyword")
#let visibility(item) = if item.visibility == "public" {
  raw("public ", lang: "storage.modifier")
}

#let path_to_doc_url(ctx, path_id) = {
  // this one is broken for some reason
  if path_id == 311 {
    return ""
  }
  let path = ctx.data.paths.at(str(path_id))
  if path.crate_id == 0 {
    return label(path.path.slice(1).join("::") + "__" + path.kind)
  }
  let crate = ctx.data.external_crates.at(str(path.crate_id))
  let root_url = crate.html_root_url
  if root_url == none {
    root_url = ctx.root_urls.at(crate.name, default: none)
  }
  if root_url == none {
    root_url = ctx.root_urls.at(crate.name.replace("_", "-"))
  }

  let resource_name = if path.kind in ("struct", "enum", "trait") {
    path.kind + "." + path.path.last() + ".html"
  } else if path.kind == "type_alias" { "type." + path.path.last() + ".html" } else if path.kind == "module" {
    path.path.last() + "/index.html"
  } else {
    panic[Unhandled path kind #path.kind]
  }
  let url = (
    root_url + path.path.slice(0, -1).join("/") + "/" + resource_name
  )
  url
}

#let item_name(item) = {
  if item.kind == "mod" and item.inner.is_crate {
    return _frag("crate") + raw(item.name, lang: "black")
  }
  visibility(item)
  if item.kind == "use" {
    _frag("import")
    raw(item.inner.source, lang: "black")
    return
  }
  if item.kind == "impl" {
    return none
  }
  if item.kind == "function" {
    if item.inner.header.is_const {
      _frag("const")
    }
    if item.inner.header.is_unsafe {
      _frag("unsafe")
    }
    if item.inner.header.is_async {
      _frag("async")
    }
  } else if item.kind == "struct" {
    if "plain" in item.inner.kind {
      _frag("struct")
    } else { _frag("tuple") }
  } else if item.kind == "variant" {
    if "struct" in item.inner.kind {
      _frag("struct")
    } else if "tuple" in item.inner.kind {
      _frag("tuple")
    }
    _frag("variant")
  }
  (
    function: _frag("function"),
    module: _frag("module"),
    enum: _frag("enum"),
    type_alias: _frag("type"),
    constant: _frag("const"),
    struct_field: _frag("field"),
    macro: _frag("macro"),
  ).at(item.kind, default: none)
  raw(
    item.name,
    lang: if item.kind == "function" {
      "entity.name.function"
    } else if item.kind == "struct_field" {
      "variable.other.member"
    },
  )
}
}

#let _in_angle_brackets(..args) = {
  assert.eq(args.named(), (:))
  ```none <```
  args.pos().join(`, `)
  ```none >```
}

#let _mutually_recursive(..funcs) = {
  assert.eq(funcs.pos(), ())
  let funcs = funcs.named()
  funcs.pairs().map(((k, v)) => (k, v.with(funcs))).to-dict()
}
#let (_type_expression, _function_output, _trait_expression, _generic_params, ..) = _mutually_recursive(
  _generic_params: (funcs, ctx, item) => {
    let (_trait_bounds, ..) = funcs
    let generics = item.inner.generics.params
    generics = generics.filter(param => "type" in param.kind and not param.kind.type.is_synthetic)
    if generics.len() == 0 {
      return
    }
    _in_angle_brackets(
      ..generics.map(param => {
        raw(param.name, lang: none)
        if param.kind.type.bounds != () {
          `: `
          _trait_bounds(funcs, ctx, param.kind.type.bounds)
        }
      }),
    )
  },
  _trait_expression: (funcs, ctx, trait) => {
    let (_generic_args, ..) = funcs
    let name = trait.path.split("::").last()
    link(
      path_to_doc_url(ctx, trait.id),
      raw(
        name,
        lang: if name
          in (
            "Copy",
            "Send",
            "Sized",
            "Sync",
            "Drop",
            "Fn",
            "FnMut",
            "FnOnce",
            "ToOwned",
            "Clone",
            "PartialEq",
            "PartialOrd",
            "Eq",
            "Ord",
            "AsRef",
            "AsMut",
            "Into",
            "From",
            "Default",
            "Iterator",
            "Extend",
            "IntoIterator",
            "DoubleEndedIterator",
            "ExactSizeIterator",
            "SliceConcatExt",
            "ToString",
          ) {
          "support.type"
        },
      ),
    )
    _generic_args(funcs, ctx, trait.args)
  },
  _trait_bounds: (funcs, ctx, bounds) => {
    let (_trait_expression, ..) = funcs
    bounds
      .map(bound => {
        let kind = bound.keys()
        assert.eq(kind.len(), 1)
        kind = kind.first()
        if kind == "trait_bound" {
          let trait = bound.trait_bound.trait
          _trait_expression(funcs, ctx, trait)
          if bound.at("generic_params", default: ()) != () {
            stub()
          }
          if bound.at("modifier", default: "none") != "none" {
            stub()
          }
        } else {
          stub()
        }
      })
      .join(raw(" + ", lang: "keyword.operator"))
  },
  _impl_trait_type: (funcs, ctx, type) => {
    let (_trait_bounds, ..) = funcs
    ```keyword implements ```
    _trait_bounds(funcs, ctx, type)
  },

  _type_expression: (funcs, ctx, type) => {
    let (_type_expression, _impl_trait_type, _generic_args) = funcs

    assert.eq(type.keys().len(), 1)
    let kind = type.keys().first()
    (
      resolved_path: it => {
        let name = it.path.split("::").last()
        link(
          path_to_doc_url(ctx, it.id),
          raw(
            name,
            lang: if name in ("String", "Result", "Option", "Vec", "Box", "Rc", "Arc", "BTreeMap", "HashMap") {
              "support.type"
            },
          ),
        )
        _generic_args(funcs, ctx, it.args)
      },
      borrowed_ref: it => {
        raw("&", lang: "keyword.operator")
        _type_expression(funcs, ctx, it.type)
      },
      raw_pointer: it => {
        raw("*", lang: "keyword.operator")
        if it.is_mutable {
          ` mut `
        } else {
          ` const `
        }
        _type_expression(funcs, ctx, it.type)
      },
      primitive: it => link(
        "https://doc.rust-lang.org/stable/std/primitive." + it + ".html",
        raw(it, lang: "storage.type.rust.builtin"),
      ),
      impl_trait: _impl_trait_type.with(funcs, ctx),
      dyn_trait: stub,
      array: it => `[` + _type_expression(funcs, ctx, it.type) + raw("; " + str(it.len)) + `]`,
      tuple: it => `(` + it.map(_type_expression.with(funcs, ctx)).join(`, `) + `)`,
      generic: it => raw(it),
      qualified_path: stub,
      slice: it => `[` + _type_expression(funcs, ctx, it) + `]`,
    ).at(kind)(type.at(kind))
  },

  _generic_args: (funcs, ctx, args) => {
    if args == none { return }
    let (_type_expression, _function_output, ..) = funcs
    if "parenthesized" in args {
      assert("angle_bracketed" not in args)

      ```none (```
      args.parenthesized.inputs.map(_type_expression.with(funcs, ctx)).join(`, `)

      ```none )```
      _function_output(funcs, ctx, args.parenthesized)
    } else {
      let args = args.angle_bracketed
      if args.constraints != () {
        stub()
      }
      args = args.args.filter(arg => "type" in arg)
      if args == () {
        return
      }
      _in_angle_brackets(..args.map(arg => _type_expression(funcs, ctx, arg.type)))
    }
  },

  _function_output: (funcs, ctx, signature) => {
    let (_type_expression, ..) = funcs
    let output = signature.output
    if output != none {
      raw("\n\t-> ")
      _type_expression(funcs, ctx, output)
    }
  },
)

#let _function_params(ctx, signature) = {
  let params = signature.inputs
  ```none (```
  params
    .map(param => {
      let name = param.first()
      let type = param.last()
      if name == "self" {
        if "borrowed_ref" in type {
          raw("&", lang: "keyword.operator")
          if type.borrowed_ref.is_mutable {
            raw("mut ", lang: "keyword")
          }
        }
        raw("self", lang: "variable.parameter")
      } else {
        raw(if name.starts-with("__arg") { "<PATTERN MATCH>" } else { name }, lang: "variable.parameter")
        `: `
        _type_expression(ctx, type)
      }
    })
    .join(`, `)

  ```none )```
}

#let _where_clause(item) = {
  if "where_predicates" not in item.inner {
    return ``
  }
  let clause = item.inner.where_predicates
  if clause == () {
    return ``
  }
  stub()
}

#let _in_braces(..args, indent: 0) = {
  assert.eq(args.named(), (:), message: "Doesn't support named arguments")
  raw("{\n")
  args
    .pos()
    .map(it => (
      box(
        stack(
          dir: ltr,
          _indent(1 + indent),
          box(it + `,`),
        ),
      )
        + linebreak()
    ))
    .join()
  _indent(indent)
  `}`
}

#let _attrs(item) = for attr in item.attrs {
  if type(attr) == dictionary {
    assert.eq(attr.keys(), ("other",))
    continue
  }
  if attr.starts-with("allow") { continue }
  if attr == "automatically_derived" { continue }
  raw("#[" + attr + "]", lang: "rs")
  linebreak()
}


#let _constant(ctx, item) = {
  `: `
  _type_expression(ctx, item.inner.type)
}

#let _use(item) = {
  visibility(item)
  _frag("use")
  if item.inner.name == item.inner.source.split("::").last() {
    raw(item.inner.source)
  } else {
    raw(item.inner.source + " as " + item.inner.name)
  }
  `;`
}

#let _type_alias(ctx, item) = {
  _generic_params(ctx, item)
  ` = `
  _type_expression(ctx, item.inner.type)
}

#let item_signature(ctx, item) = (
  code_box({
    _attrs(item)
    if item.kind == "use" {
      _use(item)
    } else if item.kind == "struct_field" and item.name.starts-with(regex("[0-9]")) {
      _type_expression(ctx, item.inner)
    } else {
      item_name(item)
      (
        function: it => {
          _generic_params(ctx, it)
          _function_params(ctx, it.inner.sig)
          _function_output(ctx, it.inner.sig)
          _where_clause(it)
          `;`
        },
        module: it => `;`,
        struct: it => {
          _generic_params(ctx, it)
          _where_clause(it)
          `;`
        },
        struct_field: it => {
          `: `
          _type_expression(ctx, it.inner)
        },
        enum: it => {
          _generic_params(ctx, it)
          _where_clause(it)
          `;`
        },
        variant: it => none,
        constant: it => _constant(ctx, it) + `;`,
        type_alias: it => _type_alias(ctx, it) + `;`,
        impl: it => if it.inner.trait != none {
          ```keyword implement```
          _generic_params(ctx, it)
          ```keyword  trait ```
          _trait_expression(ctx, it.inner.trait)
          ```keyword  for ```
          _type_expression(ctx, it.inner.for)
          `;`
        },
        assoc_type: stub,
        macro: it => ` { ... }`,
      ).at(item.kind)(item)
    }
  })
    + linebreak()
)
