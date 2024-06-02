pub type RegisterValue {
  Some(Number)
  None
}

pub type Number {
  Integer(Int)
  Float(Float)
}

pub type Token {
  Assign
  OpAdd
  OpSub
  OpMul
  OpDiv
  OpPow
  OpMod
  OpSqrt
  Variable(String)
  Number(Number)
  Nil
}

pub type NumberOperand {
  IntegerOperand(Int)
  FloatOperand(Float)
}

pub type Operand {
  VariableOperand(String)
  NumberOperand(NumberOperand)
  NilOperand
  DivisionByZeroException(String)
  InvalidArgumentsException(String)
  InvalidParityException(String)
  InvalidFractionalExponentException(String)
}
