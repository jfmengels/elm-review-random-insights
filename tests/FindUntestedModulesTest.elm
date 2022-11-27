module FindUntestedModulesTest exposing (all)

import FindUntestedModules exposing (rule)
import Review.Project as Project exposing (Project)
import Review.Test
import Review.Test.Dependencies
import Test exposing (Test, describe, test)


all : Test
all =
    describe "FindUntestedModules"
        [ test "should extract the list of untested modules" <|
            \() ->
                let
                    project : Project
                    project =
                        Review.Test.Dependencies.projectWithElmCore
                            |> Project.addModule
                                { path = "tests/SomeTest.elm"
                                , source = """
module SomeTest exposing (..)

import Imported"""
                                }
                in
                [ """module Imported exposing (..)
a = 1
"""
                , """module NotImported exposing (..)
a = 1
"""
                ]
                    |> Review.Test.runOnModulesWithProjectData project rule
                    |> Review.Test.expectDataExtract """ ["NotImported"] """
        ]
