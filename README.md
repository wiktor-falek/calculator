# Polish Notation Calculator

A calculator program that accepts input in Polish notation.

Implemented in [Gleam](https://gleam.run/), a type safe language that runs on the Erlang VM.

## Features

- **Polish Notation Support**: Allows users to input expressions in Polish notation, eliminating the need for parentheses.

- **Variable Registers**: Supports up to 10 variable registers (x0, ..., x9), allowing users to store and manipulate values and expressions.

- **Evaluation and Assignment**:
  - `e x`: Prints the value of expression x.
  - `a x1 5`: Assigns the value of 5 to the x1 register.
- **Operations**:
  - `k x y`: Adds x and y.
  - `d x y`: Multiplies x by (y + 3).
  - `e x y`: Evaluates the expression 2 \* x - y.
- **Error Handling**:
  - If a variable is referenced before being defined, it will display "Variable not defined" error.

## Example

Input:

```bash
3
a x1 k 5 7
e d 3 2
e k x1 8
```

Output:

```bash
15 //(3*(2+3))
20 //(5+7 + 8, resulting in 20)
```

## Running the project

```sh
gleam run   # Run the project
```
