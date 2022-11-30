module ModuleNameToFilePath exposing (rule)

{-|

@docs rule

-}

import Dict exposing (Dict)
import Json.Encode
import Review.Rule as Rule exposing (Rule)


{-| Get a mapping of module name to file path.

    config =
        [ ModuleNameToFilePath.rule
        ]

Maybe this is useful for some kind of build task?


## Example output

```json
{
  "Api": "src/Api.elm",
  "Article": "src/Article.elm",
  "Article.Body": "src/Article/Body.elm",
  "Asset": "src/Asset.elm",
  "Page.Article": "src/Page/Article.elm",
  "Page.Article.Editor": "src/Page/Article/Editor.elm",
  "Page.Profile": "src/Page/Profile.elm"
}
```


## Try it out

You can try this rule out by running the following command:

```bash
elm-review --template jfmengels/elm-review-random-insights/preview --report=json --extract | jq -r '.extracts.ModuleNameToFilePath'
```

-}
rule : Rule
rule =
    Rule.newProjectRuleSchema "ModuleNameToFilePath" initialContext
        |> Rule.withModuleVisitor (\schema -> schema |> Rule.withSimpleModuleDefinitionVisitor (always []))
        |> Rule.withModuleContextUsingContextCreator
            { fromModuleToProject = fromModuleToProject
            , fromProjectToModule = Rule.initContextCreator (\_ -> ())
            , foldProjectContexts = Dict.union
            }
        |> Rule.withDataExtractor dataExtractor
        |> Rule.fromProjectRuleSchema


type alias ProjectContext =
    Dict String String


initialContext : ProjectContext
initialContext =
    Dict.empty


fromModuleToProject : Rule.ContextCreator () ProjectContext
fromModuleToProject =
    Rule.initContextCreator
        (\filePath moduleName () ->
            Dict.singleton (String.join "." moduleName) filePath
        )
        |> Rule.withFilePath
        |> Rule.withModuleName


dataExtractor : ProjectContext -> Json.Encode.Value
dataExtractor projectContext =
    Json.Encode.dict identity Json.Encode.string projectContext
