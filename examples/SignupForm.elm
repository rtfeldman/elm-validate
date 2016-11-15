module SignupForm exposing (..)

import Validate exposing (..)


-- Example Using Library --


type alias Model =
    { name : String, email : String, age : String }


type Field
    = Name
    | Email
    | Age


validateModel : Model -> List ( Field, String )
validateModel =
    Validate.all
        [ .name >> ifBlank (Name => "Please enter a name.")
        , .email >> ifBlank (Email => "Please enter an email address.")
        , .age >> ifNotInt (Age => "Age must be a whole number.")
        ]


result =
    validateModel { name = "Richard", email = "", age = "abc" }
        == [ ( Email, "Please enter an email address." ), ( Age, "Age must be a whole number." ) ]


(=>) =
    (,)
