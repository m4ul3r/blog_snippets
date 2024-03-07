import stackstrings
import winim

template PRINTA(args: varargs[untyped]) =
  var buf = cast[LPSTR](LocalAlloc(LPTR, 1024))
  if cast[uint](buf) != 0:
    var length = wsprintfA(buf, args)
    WriteConsoleA(GetStdHandle(STD_OUTPUT_HANDLE), buf, length, NULL, NULL)
    LocalFree(cast[HLOCAL](buf))

template PSTR(arg: untyped): cstring =
  cast[cstring](arg[0].addr)

proc main() =
  var 
    sExample1 {.stackStringA.} = "Here is a %s example: %x"
    sExample2 {.stackStringA.} = "STACK STRING"
    i = 1337
  
  PRINTA(PSTR(sExample1), PSTR(sExample2), i)

when isMainModule:
  main()