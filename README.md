# elm-validate

`elm-validate` provides convenience functions for validating data.

It is based around the idea of a `Validator`, which runs checks on a
subject and returns a `Result` which can be be either `Ok (Valid originalSubject)`
if there were no validation errors or `Err validationErrors` if the
validation failed.

```elm
case validate someValidator someSubject of
  Ok validSubject -> ...--> (Valid someSubject)
  Err validationErrors -> ...--> List of validation errors
```

For example:

```elm
import Validate exposing (ifBlank, ifNotInt, validate)


type alias Model =
    { name : String, email : String, age : String, selections : List String }


modelValidator : Validator String Model
modelValidator =
    Validate.all
        [ ifBlank .name "Please enter a name."
        , ifBlank .email "Please enter an email address."
        , ifNotInt .age "Age must be a whole number."
        , ifEmptyList .selections "Please select at least one."
        ]


validate modelValidator
    { name = "Sam", email = "", age = "abc", selections = [ "cats" ] }
    --> Err [ "Please enter an email address.", "Age must be a whole number." ]

validate modelValidator
    { name = "Sam", email = "sam@samtown.com", age = "27", selections = [ "cats" ] }
    --> Ok (Valid { name = "Sam", email = "sam@samtown.com", age = "27", selections = [ "cats" ] })

```

You can represent your errors however you like. One nice approach is to use
tuple of the error message and the field responsible for the error:

```elm
type Field =
    Name | Email | Age | Selections


modelValidator : Validator ( Field, String ) Model
modelValidator =
    Validate.all
        [ ifBlank .name ( Name, "Please enter a name." )
        , ifBlank .email ( Email, "Please enter an email address." )
        , ifNotInt .age ( Age, "Age must be a whole number." )
        , ifEmptyList .selections ( Selections, "Please select at least one." )
        ]


type alias Model =
    { name : String, email : String, age : String }


validate modelValidator
    { name = "Sam", email = "", age = "abc", selections = [ "cats" ] }
    --> Err [ ( Email, "Please enter an email address." )
    -->   , ( Age, "Age must be a whole number." )
    -->   ]
```

Functions that detect the _absence_ of a value, such as `ifBlank` and `ifEmptyList`, accept an error as the second argument:

```elm
modelValidator : Validator ( Field, String ) Model
modelValidator =
    Validate.all
        [ ifBlank .name ( Name, "Please enter a name." )
        , ifEmptyList .selections ( Selections, "Please select at least one." )
        ]
```

Functions the detect something _wrong_ with a value, such as `isNotInt` and `isInvalidEmail`, accept a function as the second argument so you can include the incorrect value in the error message:

```elm
modelValidator : Validator ( Field, String ) Model
modelValidator =
    Validate.all
        [ ifNotInt .count (\value -> ( Count, value ++ " is not an integer." ))
        , ifInvalidEmail .email (\value -> ( Email, value ++ " is not a valid email address." ))
        ]
```
