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
    buf = cast[LPSTR](HeapAlloc(GetProcessHeap(), HEAP_ZERO_MEMORY, 1024))
    data = "AAAAAAAA".cstring
  copyMem(buf, data, data.len)
  PRINTA(buf)
  HeapFree(GetProcessHeap(), 0x00, buf)

when isMainModule:
  main()