# elm-validate

`elm-validate` provides convenience functions for validating data.

It is based around the idea of a `Validator` - a function which accepts a
subject and returns a list of errors representing anything invalid about
that subject. If the list is empty, the subject is valid.

For example:

```elm
validateModel : Model -> List String
validateModel =
    Validate.all
        [ .name  >> ifBlank "Please enter a name."
        , .email >> ifBlank "Please enter an email address."
        , .age   >> ifNotInt "Age must be a whole number."
        ]

type alias Model =
    { name : String, email : String, age : String }
```

`elm-validate` is not opinionated about how you represent your errors. For
example, you might want to represent them as a tuple of the error message
as well as the field responsible for the error:

```elm
validateModel : Model -> List (Field, String)
validateModel =
    Validate.all
        [ .name  >> ifBlank (Name, "Please enter a name.")
        , .email >> ifBlank (Email, "Please enter an email address.")
        , .age   >> ifNotInt (Age, "Age must be a whole number.")
        ]

type Field =
    Name | Email | Age

type alias Model =
    { name : String, email : String, age : String }
```
