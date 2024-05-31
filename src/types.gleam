pub type RegisterValue {
  Some(Int)
  None
}

pub type Token {
  Evaluate
  Assign
  OpAdd
  OpSub
  OpMul
  OpDiv
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
  InvalidArgumentsException(String)
  InvalidParityException(String)
}
