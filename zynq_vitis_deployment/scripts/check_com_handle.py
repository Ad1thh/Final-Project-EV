import ctypes
from ctypes import wintypes
import sys

# Windows API definitions
ntdll = ctypes.WinDLL('ntdll')
kernel32 = ctypes.WinDLL('kernel32')

SystemHandleInformation = 16
STATUS_INFO_LENGTH_MISMATCH = 0xC0000004
ObjectNameInformation = 1

class SYSTEM_HANDLE_TABLE_ENTRY_INFO(ctypes.Structure):
    _fields_ = [
        ("UniqueProcessId", wintypes.USHORT),
        ("CreatorBackTraceIndex", wintypes.USHORT),
        ("ObjectTypeIndex", ctypes.c_ubyte),
        ("HandleAttributes", ctypes.c_ubyte),
        ("HandleValue", wintypes.USHORT),
        ("Object", ctypes.c_void_p),
        ("GrantedAccess", wintypes.ULONG),
    ]

# Let's use a simpler heuristic first: test which processes we can inspect or check
import psutil
print("psutil available:", 'psutil' in sys.modules)
