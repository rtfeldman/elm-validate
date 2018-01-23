module SignupForm exposing (..)

import Validate exposing (Validator, ifBlank, ifNotInt, validate)


type alias Model =
    { name : String, email : String, age : String }


type Field
    = Name
    | Email
    | Age


modelValidator : Validator ( Field, String ) Model
modelValidator =
    Validate.all
        [ ifBlank .name ( Name, "Please enter a name." )
        , ifBlank .email ( Email, "Please enter an email address." )
        , ifNotInt .age ( Age, "Age must be a whole number." )
        ]


result : Bool
result =
    validate modelValidator { name = "Richard", email = "", age = "abc" }
        == [ ( Email, "Please enter an email address." ), ( Age, "Age must be a whole number." ) ]
