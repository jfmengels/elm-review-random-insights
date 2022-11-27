# elm-review-random-insights

Provides [`elm-review`](https://package.elm-lang.org/packages/jfmengels/elm-review/latest/) rules to gain insight into your Elm codebase.

At this point in time, this package is not meant to be published. It is a "random" collection of rules aimed to showcase
use cases for [`elm-review`'s `--extract` functionality](https://package.elm-lang.org/packages/jfmengels/elm-review/latest/#extract-information)
and potentially be used as starting points for more practical rules.


## Provided rules

- [`FindUntestedModules`](https://package.elm-lang.org/packages/jfmengels/elm-review-random-insights/1.0.0/FindUntestedModules) - Finds the modules which are not directly imported by a test module.


## Configuration

```elm
module ReviewConfig exposing (config)

import FindUntestedModules
import Review.Rule exposing (Rule)

config : List Rule
config =
    [ FindUntestedModules.rule
    ]
```


## Try it out

You can try the preview configuration above out by running the following command:

```bash
elm-review --template jfmengels/elm-review-random-insights/preview --report=json --extract
```
