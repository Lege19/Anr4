The two main sources of algorithmic complexity will be:
- Deciding what word to test next
- Deciding if an answer is close enough to be considered correct

The two main sources of model complexity will be:
- Client-server architecture
- Database

So, assume these key components are in place.
The algorithmic complexities don't really on anthing else to make sense.
Client-server architecture doesn't rely on anything else to make sense.
So it's just a quetsion of how complex the database will be.
It sounds like it would have to be a fully normalised database, so avoiding huge complexity would be a good idea.
Even so, I think I'll need to cheat on normalisation a bit by claiming that binary payloads only read by the client are atomic.

Overall, assigments, and therefore schools, aren't really needed anywhere. So the NEA version of this will just be for students.


# js ecosystem

nodejs is a javascript runtime which knows to look in node_modules for dependencies, nothing else
npm is just downloads things and puts them in node_modules, but there's also npm run ...
tsc transpiles typescript files to javascript and/or .d.ts files

vite compilerOptions:
- `isolatedModules: true`
    Enforces explicit `type` imports so that transpilers can operate on single
    files, and just ommit type information This is on by default if
    `verbaitimModuleSyntax: true` This slightly changes the semantics of imports
    for modules with side effects, so `import type {...} from ...` will not run the
    side effects (this is the default behaviour without this option too) However
    `import {type ..., type ...} from ...` will run the side effects
    Some dependencies may not support this syntax, setting `skipLibCheck` fixes this
- `useDefineForClassFields: true`
    Idk why this is needed
- `target`
    Vite completely ignores `target` because esbuild does (and I think rolldown too)

tsconfig.app.json is the tsconfig used for the webapp
tsconfig.node.json is the tsconfig used for typescript files run in node, afaik this is just vite.config.ts

the vite plugins are responsible for using the correct build tools

