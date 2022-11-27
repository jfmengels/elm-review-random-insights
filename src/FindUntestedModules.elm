module FindUntestedModules exposing (rule)

{-|

@docs rule

-}

import Elm.Syntax.ModuleName exposing (ModuleName)
import Elm.Syntax.Node as Node
import Json.Encode as Encode
import Review.Rule as Rule exposing (Rule)
import Set exposing (Set)


{-| Finds the modules which are not directly imported by a test module.

    config =
        [ FindUntestedModules.rule
        ]

This is a very crude way of attempting to find untested modules. [Code coverage tools](https://github.com/zwilias/elm-coverage)
do a better job at this than this rule could, but there may some blind spots that this rule can cover.

For instance, you might have some complex function being run as part of your tests without explicitly testing the function itself,
meaning that a code coverage tool would indicate the function as being tested, whereas in practice it may not be tested properly.

Both systems have blind spots, and maybe this kind of insight can help you detect which modules deserve more extensive testing.


## Try it out

You can try this rule out by running the following command:

```bash
elm-review --template jfmengels/elm-review-random-insights/preview --report=json --extract | jq -r '.extracts.FindUntestedModules'
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
