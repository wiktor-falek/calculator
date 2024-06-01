pub type RegisterValue {
  Some(Int)
  None
}

// pub type Number {
//   Int
//   Float
// }

pub type Token {
  Evaluate
  Assign
  OpAdd
  OpSub
  OpMul
  OpDiv
  OpPow
  OpMod
  OpSqrt
  Register(Int)
  Integer(Int)
  Nil
  InvalidValueException(String)
  InvalidRegisterException(String)
}

pub type Operand {
  RegisterOperand(Int)
  IntegerOperand(Int)
  NilOperand
  DivisionByZeroException(String)
  InvalidArgumentsException(String)
  InvalidParityException(String)
}
