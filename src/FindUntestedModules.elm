module FindUntestedModules exposing (rule)

{-|

@docs rule

-}

import Elm.Syntax.ModuleName exposing (ModuleName)
import Elm.Syntax.Node as Node
import Json.Encode as Encode
import Review.Rule as Rule exposing (Rule)
import Set exposing (Set)


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
elm-review --template SiriusStarr/elm-review-import-graph/example --rules FindUntestedModules
```

-}
rule : Rule
rule =
    Rule.newProjectRuleSchema "FindUntestedModules" initialContext
        |> Rule.withModuleVisitor moduleVisitor
        |> Rule.withModuleContextUsingContextCreator
            { fromProjectToModule = fromProjectToModule
            , fromModuleToProject = fromModuleToProject
            , foldProjectContexts = foldProjectContexts
            }
        |> Rule.withDataExtractor dataExtractor
        |> Rule.fromProjectRuleSchema


type alias ProjectContext =
    { sourceModules : Set ModuleName
    , modulesImportedInTests : Set ModuleName
    }


type alias ModuleContext =
    ()


initialContext : ProjectContext
initialContext =
    { sourceModules = Set.empty
    , modulesImportedInTests = Set.empty
    }


fromProjectToModule : Rule.ContextCreator ProjectContext ModuleContext
fromProjectToModule =
    Rule.initContextCreator (\_ -> ())


fromModuleToProject : Rule.ContextCreator ModuleContext ProjectContext
fromModuleToProject =
    Rule.initContextCreator
        (\moduleName ast isInSourceDirectories () ->
            if isInSourceDirectories then
                { sourceModules = Set.singleton moduleName
                , modulesImportedInTests = Set.empty
                }

            else
                { sourceModules = Set.empty
                , modulesImportedInTests =
                    ast.imports
                        |> List.map (Node.value >> .moduleName >> Node.value)
                        |> Set.fromList
                }
        )
        |> Rule.withModuleName
        |> Rule.withFullAst
        |> Rule.withIsInSourceDirectories


foldProjectContexts : ProjectContext -> ProjectContext -> ProjectContext
foldProjectContexts newContext previousContext =
    { sourceModules = Set.union newContext.sourceModules previousContext.sourceModules
    , modulesImportedInTests = Set.union newContext.modulesImportedInTests previousContext.modulesImportedInTests
    }


moduleVisitor :
    Rule.ModuleRuleSchema {} ModuleContext
    -> Rule.ModuleRuleSchema { hasAtLeastOneVisitor : () } ModuleContext
moduleVisitor schema =
    schema
        -- Dummy visitor
        |> Rule.withModuleDefinitionVisitor (\_ ctx -> ( [], ctx ))


dataExtractor : ProjectContext -> Encode.Value
dataExtractor projectContext =
    Set.diff projectContext.sourceModules projectContext.modulesImportedInTests
        |> Set.toList
        |> Encode.list (String.join "." >> Encode.string)
