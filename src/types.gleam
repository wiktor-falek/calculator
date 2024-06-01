pub type RegisterValue {
  Some(Number)
  None
}

pub type Number {
  Integer(Int)
  Float(Float)
}

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
  Number(Number)
  Nil
  InvalidValueException(String)
  InvalidRegisterException(String)
}

pub type NumberOperand {
  IntegerOperand(Int)
  FloatOperand(Float)
}

pub type Operand {
  RegisterOperand(Int)
  NumberOperand(NumberOperand)
  NilOperand
  DivisionByZeroException(String)
  InvalidArgumentsException(String)
  InvalidParityException(String)
}
