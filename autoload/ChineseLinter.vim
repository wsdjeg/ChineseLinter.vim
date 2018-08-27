let s:ERRORS = {}

func! ChineseLinter#AddStype(id, expr)
  call extend(s:ERRORS, {a:id : a:expr})
endf
