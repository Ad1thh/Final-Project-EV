import ctypes
from ctypes import wintypes
import psutil
import os

ntdll = ctypes.WinDLL('ntdll')
kernel32 = ctypes.WinDLL('kernel32')

SystemExtendedHandleInformation = 64
STATUS_INFO_LENGTH_MISMATCH = 0xC0000004
STATUS_SUCCESS = 0

class SYSTEM_HANDLE_TABLE_ENTRY_INFO_EX(ctypes.Structure):
    _fields_ = [
        ("Object", ctypes.c_void_p),
        ("UniqueProcessId", ctypes.c_size_t),
        ("HandleValue", ctypes.c_size_t),
        ("GrantedAccess", wintypes.ULONG),
        ("CreatorBackTraceIndex", wintypes.USHORT),
        ("ObjectTypeIndex", wintypes.USHORT),
        ("HandleAttributes", wintypes.ULONG),
        ("Reserved", wintypes.ULONG),
    ]

size = wintypes.ULONG(1024 * 1024 * 8)
buf = ctypes.create_string_buffer(size.value)

while True:
    status = ntdll.NtQuerySystemInformation(SystemExtendedHandleInformation, buf, size, ctypes.byref(size))
    if status == 0:
        break
    elif status == -1073741820:
        size.value = size.value * 2
        buf = ctypes.create_string_buffer(size.value)
    else:
        print(f"NtQuerySystemInformation failed: 0x{status & 0xffffffff:08x}")
        break

if status == 0:
    number_of_handles = ctypes.cast(buf, ctypes.POINTER(ctypes.c_size_t))[0]
    entries_array = ctypes.cast(
        ctypes.byref(buf, ctypes.sizeof(ctypes.c_size_t) * 2),
        ctypes.POINTER(SYSTEM_HANDLE_TABLE_ENTRY_INFO_EX)
    )
    
    procs = {p.pid: p.name() for p in psutil.process_iter(['name'])}
    
    pid_handles = {}
    for i in range(number_of_handles):
        entry = entries_array[i]
        pid = entry.UniqueProcessId
        pid_handles.setdefault(pid, []).append(entry.HandleValue)
        
    PROCESS_DUP_HANDLE = 0x0040
    for pid, handles in pid_handles.items():
        if pid == os.getpid() or pid == 0 or pid == 4:
            continue
        hProc = kernel32.OpenProcess(PROCESS_DUP_HANDLE, False, pid)
        if not hProc:
            continue
        pname = procs.get(pid, 'unknown')
        for h in handles:
            target_h = wintypes.HANDLE()
            if kernel32.DuplicateHandle(hProc, wintypes.HANDLE(h), kernel32.GetCurrentProcess(), ctypes.byref(target_h), 0, False, 2):
                name_buf = ctypes.create_string_buffer(2048)
                ret_len = wintypes.ULONG()
                st = ntdll.NtQueryObject(target_h, 1, name_buf, 2048, ctypes.byref(ret_len))
                if st == 0:
                    length = int.from_bytes(name_buf[0:2], 'little')
                    if length > 0:
                        name_str = name_buf[ctypes.sizeof(ctypes.c_void_p)*2 : ctypes.sizeof(ctypes.c_void_p)*2 + length].decode('utf-16le', errors='ignore')
                        if 'vcp0' in name_str.lower():
                            print(f"[FOUND OWNER!] PID: {pid} ({pname}) -> {name_str}")
                kernel32.CloseHandle(target_h)
        kernel32.CloseHandle(hProc)
