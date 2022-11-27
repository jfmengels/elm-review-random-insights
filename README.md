# elm-review-random-insights

Provides [`elm-review`](https://package.elm-lang.org/packages/jfmengels/elm-review/latest/) rules to REPLACEME.


## Provided rules

- [`FindUntestedModules`](https://package.elm-lang.org/packages/jfmengels/elm-review-random-insights/1.0.0/FindUntestedModules) - Reports REPLACEME.


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

You can try the example configuration above out by running the following command:

```bash
elm-review --template jfmengels/elm-review-random-insights/example
```