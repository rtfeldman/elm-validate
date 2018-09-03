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

To display the errors we can pattern match for a failed validation result,
and then `map` over the strings to convert them for display, in this case
to an un-ordered list showing each of the errors.

```elm
view model =
    let
        validationResult =
            validate modelValidator model

        errorDisplay =
            case validationResult of
                Ok _ ->
                    div [] []

                Err errors ->
                    ul [] (List.map (\error -> li [] [ text error ]) errors)
    in
    div []
        [ form []
            [ errorDisplay
            , input [ value model.name, placeholder "Please enter your name...", onInput UpdateName ] []
            , input [ value model.email, placeholder "Please enter your email...", onInput UpdateEmail ] []
            -- other form fields ...
            ]
        ]

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

If your errors are in this format its easy to extract them and display them
next to the field which produced the error.

```elm

-- Helper function to extract a specific fields errors from the validation result
errorElements: Field -> Result (List ( Field, String )) (Valid Model) -> Html msg
errorElements field validationResult =
    case validationResult of
        Ok _ ->
            div [] []

        Err errors ->
            let
                fieldErrors =
                    errors
                        |> List.filter (\( f, _ ) -> f == field)
                        |> List.map (\( _, error ) -> li [] [ text error ])
            in
            ul [] fieldErrors

view model =
    let
        validationResult =
            validate modelValidator model
    in
    div []
        [ form []
            [ input [ value model.name, placeholder "Please enter your name...", onInput UpdateName ] []
            , errorElements Name validationResult
            , input [ value model.email, placeholder "Please enter your email...", onInput UpdateEmail ] []
            , errorElements Email validationResult
            -- other form fields ...
            ]
        ]

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
