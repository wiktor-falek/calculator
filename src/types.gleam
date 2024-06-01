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
  Float(Float)
  Nil
  InvalidValueException(String)
  InvalidRegisterException(String)
}

pub type Operand {
  RegisterOperand(Int)
  IntegerOperand(Int)
  FloatOperand(Float)
  NilOperand
  DivisionByZeroException(String)
  InvalidArgumentsException(String)
  InvalidParityException(String)
}
