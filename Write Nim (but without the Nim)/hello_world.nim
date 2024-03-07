import winim 

template PRINTA(args: varargs[untyped]) =
  var buf = cast[LPSTR](LocalAlloc(LPTR, 1024))
  if cast[uint](buf) != 0:
    var length = wsprintfA(buf, args)
    WriteConsoleA(GetStdHandle(STD_OUTPUT_HANDLE), buf, length, NULL, NULL)
    LocalFree(cast[HLOCAL](buf))

proc main() = 
  PRINTA("%s, I am %s", "hello world", "user")

when isMainModule:
  main()