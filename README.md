# Polish Notation Calculator

A calculator program that accepts input in [Reverse Polish notation](https://en.wikipedia.org/wiki/Reverse_Polish_notation).

Implemented in [Gleam](https://gleam.run/), a type safe functional language that runs on the Erlang VM.

## Features

- **Postfix Notation**: Allows users to input expressions where operators follow the operands, eliminating the need for parenthesis.

- **Variable Registers**: Supports a customizable amount of variable registers (x1 to x10 by default), allowing users to store values in memory.

- **Register Assignments**:
  - `x1 5 a`: Assigns the value of 5 to the x1 register.
  - `2 x1 5 a *`: Assignments return the register value, allowing the use of assignments as an argument for another operation
- **Example Operations**:
  - `1 2 +`: 1 + 2
  - `3 2 1 + *`: (1 + 2) \* 3
  - `1 2 3 * +`: 1 + 2 \* 3

## Running the project

```sh
gleam run   # Run the project
```
