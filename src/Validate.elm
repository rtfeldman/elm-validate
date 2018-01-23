module Validate
    exposing
        ( Validator
        , all
        , any
        , firstError
        , ifBlank
        , ifEmptyDict
        , ifEmptyList
        , ifEmptySet
        , ifInvalid
        , ifInvalidEmail
        , ifNotInt
        , ifNothing
        , isBlank
        , isInt
        , isValidEmail
        , validate
        )

{-| Convenience functions for validating data.


# Validating a subject

@docs Validator, validate


# Creating validators

@docs ifBlank, ifNotInt, ifEmptyList, ifEmptyDict, ifEmptySet, ifNothing, ifInvalidEmail, ifInvalid


# Combining validators

@docs all, any, firstError


# Checking values directly

@docs isBlank, isInt, isValidEmail

-}

import Dict exposing (Dict)
import Regex exposing (Regex)
import Set exposing (Set)
import String


-- VALIDATING A SUBJECT --


{-| A `Validator` contains a function which takes a subject and returns a list
of errors describing anything invalid about that subject.

Pass it to [`validate`](#validate) to get the list of errors.
An empty error list means the subject was valid.

-}
type Validator error subject
    = Validator (subject -> List error)


{-| Return an error if the given predicate returns `True` for the given
subject.

    import Validate exposing (ifBlank, ifNotInt, validate)

    errors : Model -> List String
    errors model =
        validate modelValidator model

    modelValidator : Validator Model String
    modelValidator =
        Validate.all
            [ ifBlank .name "Please enter a name."
            , ifBlank .email "Please enter an email address."
            , ifNotInt .age "Age must be a whole number."
            , ifEmptyList .selections "Please select at least one."
            ]

-}
validate : Validator error subject -> subject -> List error
validate (Validator getErrors) subject =
    getErrors subject



-- CONSTRUCTING VALIDATORS --


{-| Return an error if the given `String` is empty, or if it contains only
whitespace characters.

    import Validate exposing (ifBlank, ifNotInt)

    modelValidator : Validator Model String
    modelValidator =
        Validate.all
            [ ifBlank .name "Please enter a name."
            , ifBlank .email "Please enter an email address."
            ]

-}
ifBlank : (subject -> String) -> error -> Validator error subject
ifBlank subjectToString error =
    let
        getErrors subject =
            if isBlank (subjectToString subject) then
                [ error ]
            else
                []
    in
    Validator getErrors


{-| Return an error if the given `String` cannot be parsed as an `Int`.
-}
ifNotInt : (subject -> String) -> error -> Validator error subject
ifNotInt subjectToString error =
    let
        getErrors subject =
            if isInt (subjectToString subject) then
                []
            else
                [ error ]
    in
    Validator getErrors


{-| Return an error if the given `List` is empty.
-}
ifEmptyList : error -> Validator error (List a)
ifEmptyList =
    ifInvalid List.isEmpty


{-| Return an error if the given `Dict` is empty.
-}
ifEmptyDict : error -> Validator error (Dict comparable v)
ifEmptyDict error =
    ifInvalid Dict.isEmpty error


{-| Return an error if the given `Set` is empty.
-}
ifEmptySet : error -> Validator error (Set comparable)
ifEmptySet error =
    ifInvalid Set.isEmpty error


{-| Return an error if given a `Maybe` that is `Nothing`.
-}
ifNothing : error -> Validator error (Maybe a)
ifNothing error =
    ifInvalid isNothing error


{-| Return an error if the given email string is malformed.
-}
ifInvalidEmail : error -> Validator error String
ifInvalidEmail error =
    ifInvalid isInvalidEmail error


{-| Return an error if the given predicate returns `True` for the given
subject.

    import Validate exposing (ifInvalid)

    modelValidator : Validator Model String
    modelValidator =
        ifInvalid (\model -> countSelected model < 2)
            "Please select at least two."

-}
ifInvalid : (subject -> Bool) -> error -> Validator error subject
ifInvalid test error =
    let
        getErrors subject =
            if test subject then
                [ error ]
            else
                []
    in
    Validator getErrors



-- COMBINING VALIDATORS --


{-| Run each of the given validators, in order, and return their concatenated
error lists.

    import Validate exposing (ifBlank, ifNotInt)

    modelValidator : Validator Model String
    modelValidator =
        Validate.all
            [ ifBlank .name "Please enter a name."
            , ifBlank .email "Please enter an email address."
            , ifNotInt .age "Age must be a whole number."
            ]

-}
all : List (Validator error subject) -> Validator error subject
all validators =
    let
        validator subject =
            let
                accumulateErrors (Validator getErrors) totalErrors =
                    totalErrors ++ getErrors subject
            in
            List.foldl accumulateErrors [] validators
    in
    Validator validator


{-| Run each of the given validators, in order, stopping after the first error
and returning it. If no errors are encountered, return `Nothing`.
-}
firstError : List (Validator error subject) -> subject -> Maybe error
firstError validators subject =
    case validators of
        [] ->
            Nothing

        (Validator getErrors) :: others ->
            case getErrors subject of
                [] ->
                    firstError others subject

                error :: _ ->
                    Just error


{-| Return `True` if none of the given validators returns any errors for the given
subject, and `False` if any validator returns one or more errors.
-}
any : List (Validator error subject) -> subject -> Bool
any validators subject =
    case validators of
        [] ->
            True

        (Validator getErrors) :: others ->
            case getErrors subject of
                [] ->
                    any others subject

                error :: _ ->
                    False



-- CHECKING VALUES DIRECTLY --


{-| Returns `True` if the given string is nothing but whitespace.

[`ifBlank`](#ifBlank) uses this under the hood.

-}
isBlank : String -> Bool
isBlank str =
    Regex.contains lacksNonWhitespaceChars str


{-| Returns `True` if the email is malformed.

[`ifInvalidEmail`](#ifInvalidEmail) uses this under the hood.

-}
isValidEmail : String -> Bool
isValidEmail email =
    Regex.contains validEmail email


{-| Returns `True` if `String.toInt` on the given string returns an `Ok`.

[`ifNotInt`](#ifNotInt) uses this under the hood.

-}
isInt : String -> Bool
isInt str =
    case String.toInt str of
        Ok _ ->
            True

        Err _ ->
            False



-- INTERNAL HELPERS --


lacksNonWhitespaceChars : Regex
lacksNonWhitespaceChars =
    Regex.regex "^\\s*$"


validEmail : Regex
validEmail =
    Regex.regex "^[a-zA-Z0-9.!#$%&'*+\\/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$"
        |> Regex.caseInsensitive


isInvalidEmail : String -> Bool
isInvalidEmail email =
    not (isValidEmail email)


isNothing : Maybe a -> Bool
isNothing subject =
    case subject of
        Just _ ->
            False

        Nothing ->
            True
