## Releases
| Version | Notes |
| ------- | ----- |
| [**4.0.0**](https://github.com/rtfeldman/elm-validate/tree/4.0.0) | Add `Valid` and `fromValid`, change `validate` to return `Result (List error) (Valid subject)`.
| [**3.1.0**](https://github.com/rtfeldman/elm-validate/tree/3.1.0) | Add `isFloat` and `ifNotFloat`.
| [**3.0.0**](https://github.com/rtfeldman/elm-validate/tree/3.0.0) | Give `ifNotInt` and `ifInvalidEmail` context on what the invalid value was. Add `Validate.fromErrors.`
| [**2.0.0**](https://github.com/rtfeldman/elm-validate/tree/2.0.0) | Change Validator to be a union type, replace `ifInvalid` with `ifTrue` and `ifFalse`, rearrange arguments of `ifBlank` and similar functions, replace `eager` with `firstError`, and expose `isBlank`, `isInt`, and `isValidEmail`.
| [**1.0.0**](https://github.com/rtfeldman/elm-validate/tree/1.0.0) | Initial Release
