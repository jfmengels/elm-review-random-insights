module FindUntestedModules exposing (rule)

{-|

@docs rule

-}

import Review.Rule as Rule exposing (Rule)


{-| Reports... REPLACEME

    config =
        [ FindUntestedModules.rule
        ]


## Fail

    a =
        "REPLACEME example to replace"


## Success

    a =
        "REPLACEME example to replace"


## When (not) to enable this rule

This rule is useful when REPLACEME.
This rule is not useful when REPLACEME.


## Try it out

You can try this rule out by running the following command:

```bash
elm-review --template jfmengels/elm-review-random-insights/example --rules FindUntestedModules
```

-}
rule : Rule
rule =
    Rule.newModuleRuleSchema "FindUntestedModules" ()
        -- Add your visitors
        |> Rule.fromModuleRuleSchema