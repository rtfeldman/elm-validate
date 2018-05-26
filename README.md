# elm-validate

`elm-validate` provides convenience functions for validating data.

It is based around the idea of a `Validator`, which runs checks on a
subject and returns a list of errors representing anything invalid about
that subject. If the list is empty, the subject is valid.

For example:

```elm
import Validate exposing (ifBlank, ifNotInt, ifInvalidDate, validate)


type alias Model =
    { name : String, email : String, age : String, selections : List String, born : Date }


modelValidator : Validator String Model
modelValidator =
    Validate.all
        [ ifBlank .name "Please enter a name."
        , ifBlank .email "Please enter an email address."
        , ifNotInt .age "Age must be a whole number."
        , ifEmptyList .selections "Please select at least one."
        , ifInvalidDate .born "Please enter a valid date."
        ]


validate modelValidator
    { name = "Sam", email = "", age = "abc", selections = [ "cats" ], born = "2018-13-31" }
    --> [ "Please enter an email address.", "Age must be a whole number.", "Please enter a valid date." ]
```

You can represent your errors however you like. One nice approach is to use
tuple of the error message and the field responsible for the error:

```elm
type Field =
    Name | Email | Age | Selections | Born


modelValidator : Validator ( Field, String ) Model
modelValidator =
    Validate.all
        [ ifBlank .name ( Name, "Please enter a name." )
        , ifBlank .email ( Email, "Please enter an email address." )
        , ifNotInt .age ( Age, "Age must be a whole number." )
        , ifEmptyList .selections ( Selections, "Please select at least one." )
        , ifInvalidDate .born ( Born, "Please enter a valid date." )
        ]


type alias Model =
    { name : String, email : String, age : String, born : Date }


validate modelValidator
    { name = "Sam", email = "", age = "abc", selections = [ "cats" ], date = "2018-13-31" }
    --> [ ( Email, "Please enter an email address." )
    --> , ( Age, "Age must be a whole number." )
    --> , ( Born, "Please enter a valid date." )
    --> ]
```
