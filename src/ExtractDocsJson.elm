module ExtractDocsJson exposing (rule)

{-|

@docs rule

-}

import Dict exposing (Dict)
import Elm.Syntax.Declaration as Declaration exposing (Declaration)
import Elm.Syntax.ModuleName exposing (ModuleName)
import Elm.Syntax.Node as Node exposing (Node(..))
import Elm.Syntax.Type as Type
import Elm.Syntax.TypeAnnotation as TypeAnnotation exposing (TypeAnnotation)
import Json.Encode as Encode
import Review.Rule as Rule exposing (Rule)


{-| Recreate `docs.json` for your project.

**Note:** This is only a proof of concept and not entirely polished or working. Help would be appreciated :)

    config =
        [ ExtractDocsJson.rule
        ]

Maybe this is an interesting start for generating documentation for your project.


## Try it out

You can try this rule out by running the following command:

```bash
elm-review --template jfmengels/elm-review-random-insights/preview --report=json --extract | jq -r '.extracts.ExtractDocsJson'
```

-}
rule : Rule
rule =
    Rule.newProjectRuleSchema "ExtractDocsJson" initContext
        |> Rule.withModuleVisitor moduleVisitor
        |> Rule.withModuleContextUsingContextCreator
            { fromProjectToModule = fromProjectToModule
            , fromModuleToProject = fromModuleToProject
            , foldProjectContexts = foldProjectContexts
            }
        |> Rule.withDataExtractor dataExtractor
        |> Rule.fromProjectRuleSchema


type alias ProjectContext =
    Dict String Module


type alias Module =
    { name : String
    , comment : String
    , unions : List Union
    , aliases : List Alias
    , values : List Value
    }


type alias ModuleContext =
    { moduleName : Node ModuleName
    , shouldBeIncluded : Bool
    , comment : String
    , unions : List Union
    , aliases : List Alias
    , values : List Value
    }


type alias Union =
    { name : String
    , comment : String
    , args : List String
    , tags : List ( String, List String )
    }


type alias Alias =
    { name : String
    , comment : String
    , args : List String
    , tipe : String
    }


type alias Value =
    { name : String
    , comment : String
    , tipe : String
    }


initContext : ProjectContext
initContext =
    Dict.empty


fromProjectToModule : Rule.ContextCreator ProjectContext ModuleContext
fromProjectToModule =
    Rule.initContextCreator
        (\moduleNameNode isInSourceDirectories _ ->
            { moduleName = moduleNameNode
            , shouldBeIncluded = isInSourceDirectories
            , comment = ""
            , unions = []
            , aliases = []
            , values = []
            }
        )
        |> Rule.withModuleNameNode
        |> Rule.withIsInSourceDirectories


fromModuleToProject : Rule.ContextCreator ModuleContext ProjectContext
fromModuleToProject =
    Rule.initContextCreator
        (\moduleContext ->
            if moduleContext.shouldBeIncluded then
                let
                    name : String
                    name =
                        moduleContext.moduleName |> Node.value |> String.join "."
                in
                Dict.singleton
                    name
                    { name = name
                    , comment = moduleContext.comment
                    , unions = moduleContext.unions
                    , aliases = moduleContext.aliases
                    , values = moduleContext.values
                    }

            else
                Dict.empty
        )


foldProjectContexts : ProjectContext -> ProjectContext -> ProjectContext
foldProjectContexts =
    Dict.union


moduleVisitor :
    Rule.ModuleRuleSchema {} ModuleContext
    -> Rule.ModuleRuleSchema { hasAtLeastOneVisitor : () } ModuleContext
moduleVisitor schema =
    schema
        |> Rule.withModuleDocumentationVisitor moduleDocumentationVisitor
        |> Rule.withDeclarationEnterVisitor declarationVisitor


moduleDocumentationVisitor : Maybe (Node String) -> ModuleContext -> ( List (Rule.Error {}), ModuleContext )
moduleDocumentationVisitor maybeNode moduleContext =
    if moduleContext.shouldBeIncluded then
        let
            comment : String
            comment =
                case maybeNode of
                    Just moduleDocumentation ->
                        Node.value moduleDocumentation
                            |> String.slice 3 -2

                    Nothing ->
                        missing
        in
        ( [], { moduleContext | comment = comment } )

    else
        ( [], moduleContext )


declarationVisitor : Node Declaration -> ModuleContext -> ( List (Rule.Error {}), ModuleContext )
declarationVisitor node moduleContext =
    if moduleContext.shouldBeIncluded then
        case Node.value node of
            Declaration.FunctionDeclaration { declaration, documentation, signature } ->
                let
                    value : Value
                    value =
                        { name = Node.value (Node.value declaration).name
                        , comment =
                            documentation
                                |> Maybe.map Node.value
                                |> Maybe.withDefault missing
                        , tipe =
                            signature
                                |> Maybe.map (\signature_ -> Node.value signature_ |> .typeAnnotation |> typeToString)
                                |> Maybe.withDefault missing
                        }
                in
                ( [], { moduleContext | values = value :: moduleContext.values } )

            Declaration.AliasDeclaration declaration ->
                let
                    alias : Alias
                    alias =
                        { name = Node.value declaration.name
                        , comment =
                            declaration.documentation
                                |> Maybe.map Node.value
                                |> Maybe.withDefault missing
                        , args = List.map Node.value declaration.generics
                        , tipe = typeToString declaration.typeAnnotation
                        }
                in
                ( [], { moduleContext | aliases = alias :: moduleContext.aliases } )

            Declaration.CustomTypeDeclaration declaration ->
                let
                    union : Union
                    union =
                        { name = Node.value declaration.name
                        , comment =
                            declaration.documentation
                                |> Maybe.map Node.value
                                |> Maybe.withDefault missing
                        , args = List.map Node.value declaration.generics
                        , tags = List.map tagToString declaration.constructors
                        }
                in
                ( [], { moduleContext | unions = union :: moduleContext.unions } )

            _ ->
                ( [], moduleContext )

    else
        ( [], moduleContext )


tagToString : Node Type.ValueConstructor -> ( String, List String )
tagToString (Node _ { name, arguments }) =
    ( Node.value name
    , List.map typeToString arguments
    )


missing : String
missing =
    "MISSING"


dataExtractor : ProjectContext -> Encode.Value
dataExtractor projectContext =
    projectContext
        |> Dict.values
        |> Encode.list encodeDocsJson


encodeDocsJson : Module -> Encode.Value
encodeDocsJson doc =
    Encode.object
        [ ( "name", Encode.string doc.name )
        , ( "comment", Encode.string doc.comment )
        , ( "unions", Encode.list unionEncoder doc.unions )
        , ( "aliases", Encode.list aliasEncoder doc.aliases )
        , ( "values", Encode.list valueEncoder doc.values )
        , ( "binops", Encode.list identity [] )
        ]


aliasEncoder : Alias -> Encode.Value
aliasEncoder v =
    Encode.object
        [ ( "name", Encode.string v.name )
        , ( "comment", Encode.string v.comment )
        , ( "args", Encode.list Encode.string v.args )
        , ( "type", Encode.string v.tipe )
        ]


unionEncoder : Union -> Encode.Value
unionEncoder v =
    Encode.object
        [ ( "name", Encode.string v.name )
        , ( "comment", Encode.string v.comment )
        , ( "args", Encode.list Encode.string v.args )
        , ( "cases", Encode.list tagEncoder v.tags )
        ]


tagEncoder : ( String, List String ) -> Encode.Value
tagEncoder ( name, tipe ) =
    Encode.list identity
        [ Encode.string name
        , Encode.list Encode.string tipe
        ]


valueEncoder : Value -> Encode.Value
valueEncoder v =
    Encode.object
        [ ( "name", Encode.string v.name )
        , ( "comment", Encode.string v.comment )
        , ( "type", Encode.string v.tipe )
        ]


typeToString : Node TypeAnnotation -> String
typeToString tipe =
    case Node.value tipe of
        TypeAnnotation.GenericType string ->
            string

        TypeAnnotation.FunctionTypeAnnotation left right ->
            typeToString left ++ " -> " ++ typeToString right

        TypeAnnotation.Typed (Node _ ( moduleName, name )) arguments ->
            String.join "." (moduleName ++ [ name ])
                :: List.map typeToString arguments
                |> String.join " "

        TypeAnnotation.Unit ->
            "()"

        TypeAnnotation.Tupled types ->
            "( " ++ String.join ", " (List.map typeToString types) ++ " )"

        TypeAnnotation.Record fields ->
            "{ " ++ recordFieldsToString fields ++ " }"

        TypeAnnotation.GenericRecord (Node _ var) (Node _ fields) ->
            "{ " ++ var ++ " | " ++ recordFieldsToString fields ++ " }"


recordFieldsToString : List (Node ( Node String, Node TypeAnnotation )) -> String
recordFieldsToString fields =
    List.map (Node.value >> recordFieldToString) fields
        |> String.join ", "


recordFieldToString : ( Node String, Node TypeAnnotation ) -> String
recordFieldToString ( Node _ name, fieldType ) =
    name ++ " : " ++ typeToString fieldType
