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
  InvalidValueException(String)
  InvalidRegisterException(String)
}

pub type Operand {
  RegisterOperand(Int)
  IntegerOperand(Int)
  InvalidArgumentsException(String)
  InvalidParityException(String)
  Nil
}
