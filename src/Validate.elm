module Validate (Validator, (:=), succeed, all, ifBlank, ifNotInt, ifEmptyDict, ifEmptySet) where
{-| Convenience functions for working with validations

# Validation
@docs Validator, (:=), all, errorsFor, filterField, dropField

# Common Validators
@docs succeed, fail, ifBlank, ifNotInt, ifEmptyDict, ifEmptySet

-}

import String
import Dict exposing (Dict)
import Set exposing (Set)
import Regex exposing (Regex)


type alias Validator subject error =
    (subject -> List error)


{-| Run a validator on a subject and convert any resulting errors into tuples,
with the given tag as the first element of each tuple. This is useful when
you want to classify errors for later filtering.

For example, you might tag each form validation error with the associated form
field, so that when you are later rendering a given field, you can quickly
filter down to the relevant errors that should display next to that field.

    -- Simple Example --

    validateName : Validator { name : String } (String, String)
    validateName model =
        "Name" := ifBlank "Please fill in this field." model.name

    validateName { name = "" }    == [("Name", "Please fill in this field.")]
    validateName { name = "Foo" } == []


    -- Advanced Example --

    type FormField =
        Name | Email | Age


    type alias FormData =
        { name : String, email : String, age : String }


    validators =
        [
            Name :=
                .name >> ifBlank "Please enter a name.",

            Email :=
                .email >> ifBlank "Please enter an email address.",

            Email :=
                .email >> ifInvalidEmail "This is not a valid email address.",

            Age :=
                .age >> ifBlank "Please enter your age.",

            Age :=
                .age >> ifNotInt "Please enter a valid integer for your age."
        ]


    getAllFormErrors : FormData -> List (FormField, String)
    getAllFormErrors formData =
        Validate.all validators formData


    getAllFormErrors { name = "", email = "adsf", age = "1" } ==
        [
            (Name,  "Please enter a name."),
            (Email, "This is not a valid email address.")
        ]

    getAllFormErrors { name = "foo", email = "", age = "" }
        [
            (Email, "Please enter an email address."),
            (Email, "This is not a valid email address."),
            (Age,   "Please enter your age."),
            (Age,   "Please enter a valid integer for your age.")
        ]
-}
(:=) : tag -> Validator subject error -> Validator subject (tag, error)
(:=) tag validator subject =
    validator subject
        |> List.map ((,) tag)

{- We want := to have lower precedence than >> so we can write this:

    Name :=
        .name >> ifBlank "Please enter a name.",
-}
infixl 1 :=


{-| Run all the given validators, in order, on the given subject.

    mandatoryInt : Validator String String
    mandatoryInt =
        Validate.all
            [
                ifBlank "Cannot be blank.",
                ifNotInt "Must be an integer."
            ]
-}
all : List (Validator subject error) -> Validator subject error
all validators =
    let
        validate subject =
            let
                accumulateErrors validator errors =
                    errors ++ (validator subject)
            in
                List.foldl accumulateErrors [] validators
    in
        validate


{-| A validator that always returns no errors.

    nameValidator =
        if validationsEnabled then
            .name := ifBlank "Please enter a name."
        else
            succeed
-}
succeed : Validator subject error
succeed =
    always []


{-| A validator that always returns the given errors.

    passwordValidator =
        if accountLocked then
            fail ["This account is locked."]
        else
            .password := ifBlank "Please enter a password."
-}
fail : List error -> Validator subject error
fail errors =
    always errors


{-| Given a field and a list of field/error pairs, returns
only the errors that are paired with that field.

    errors =
        [
            (Name,  "cannot be blank"),
            (Name,  "must begin with a capital letter"),
            (Email, "must be a properly formatted email address"),
            (Email, "cannot exceed 255 characters"),
            (Age,   "cannot be blank")
        ]

    errorsFor Email errors ==
        [
            "must be a properly formatted email address",
            "cannot exceed 255 characters"
        ]
-}
errorsFor : field -> List (field, err) -> List err
errorsFor fieldVal errors =
    filterField ((==) fieldVal) errors
        |> List.map snd


{-| Return the given list of field/error pairs without the pairs that contain
the given field.

    errors =
        [
            (Name,  "cannot be blank"),
            (Name,  "must begin with a capital letter"),
            (Email, "must be a properly formatted email address"),
            (Email, "cannot exceed 255 characters"),
            (Age,   "cannot be blank")
        ]

    dropField Name errors ==
        [
            (Email, "must be a properly formatted email address"),
            (Email, "cannot exceed 255 characters"),
            (Age,   "cannot be blank")
        ]
-}
dropField : field -> List (field, err) -> List (field, err)
dropField droppedField errors =
    filterField ((/=) droppedField) errors


{-| Return the field/error pairs whose fields pass the given test.

    errors =
        [
            (Name,  "cannot be blank"),
            (Name,  "must begin with a capital letter"),
            (Email, "must be a properly formatted email address"),
            (Email, "cannot exceed 255 characters"),
            (Age,   "cannot be blank")
        ]

    filterField (\field -> field == Age) errors
        == [ (Age, "cannot be blank") ]
-}
filterField : (field -> Bool) -> List (field, err) -> List (field, err)
filterField test errors =
    errors
        |> List.filter (\(field, _) -> test field)


isBlankRegex : Regex
isBlankRegex =
    Regex.regex "^\\s*$"


{-| Validates that the given String contains non-whitespace characters.

    validator =
        ifBlank "cannot be blank"

    validator ""      == ["cannot be blank"]
    validator " "     == ["cannot be blank"]
    validator " foo " == []
-}
ifBlank : error -> Validator String error
ifBlank error str =
    if Regex.contains isBlankRegex str then
        [error]
    else
        []


{-| Validates that the given String can be parsed as an Int.

    validator =
        ifNotInt "please enter a valid integer"

    validator ""      == ["please enter a valid integer"]
    validator " "     == ["please enter a valid integer"]
    validator " 1"    == ["please enter a valid integer"]
    validator "1.0"   == ["please enter a valid integer"]
    validator "1.1"   == ["please enter a valid integer"]
    validator "0"     == []
    validator "1"     == []
    validator "-1"    == []
-}
ifNotInt : error -> Validator String error
ifNotInt error str =
    case String.toInt str of
        Ok _ ->
            []

        Err _ ->
            [error]


{-| Validates that the given Dict is not empty.

    validator =
        ifEmptyDict "cannot be empty"

    validator Dict.empty               == ["cannot be empty"]
    validator (Dict.fromList [(1, 2)]) == []
-}
ifEmptyDict : error -> Dict comparable v -> List error
ifEmptyDict error dict =
    if Dict.isEmpty dict then
        [error]
    else
        []


{-| Validates that the given Set is not empty.

    validator =
        ifEmptySet "cannot be empty"

    validator Set.empty                     == ["cannot be empty"]
    validator (Set.fromList ["foo", "bar"]) == []
-}
ifEmptySet : error -> Set comparable -> List error
ifEmptySet error set =
    if Set.isEmpty set then
        [error]
    else
        []
