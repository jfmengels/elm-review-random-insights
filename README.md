# elm-review-random-insights

Provides [`elm-review`](https://package.elm-lang.org/packages/jfmengels/elm-review/latest/) rules to gain insight into your Elm codebase.

At this point in time, this package is not meant to be published. It is a "random" collection of rules aimed to showcase
use cases for [`elm-review`'s `--extract` functionality](https://package.elm-lang.org/packages/jfmengels/elm-review/latest/#extract-information)
and potentially be used as starting points for more practical rules.


## Provided rules

- [`ExtractDocsJson`](https://elm-doc-preview.netlify.app/ExtractDocsJson?repo=jfmengels%2Felm-review-random-insights&version=main) - Recreate `docs.json` for your project.
- [`FindUntestedModules`](https://elm-doc-preview.netlify.app/FindUntestedModules?repo=jfmengels%2Felm-review-random-insights&version=main) - Finds the modules which are not directly imported by a test module.
- [`ModuleNameToFilePath`](https://elm-doc-preview.netlify.app/ModuleNameToFilePath?repo=jfmengels%2Felm-review-random-insights&version=main) - Get a mapping of module name to file path.


## Configuration

```elm
module ReviewConfig exposing (config)

import ExtractDocsJson
import FindUntestedModules
import ModuleNameToFilePath
import Review.Rule exposing (Rule)

config : List Rule
config =
    [ ExtractDocsJson.rule
    , FindUntestedModules.rule
    , ModuleNameToFilePath.rule
    ]
```


## Try it out

You can try the preview configuration above out by running the following command:

```bash
elm-review --template jfmengels/elm-review-random-insights/preview --report=json --extract
```
