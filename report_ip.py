#!/usr/bin/env python3
"""
Send the machine’s IP address to Klipper/Moonraker’s M117 display.
If no non-loopback IPv4 address is found, send a short error message instead.
"""

import socket
import requests
import fcntl
import struct
import os
import sys
from typing import Union

MOONRAKER_API = "http://localhost:7125/printer/gcode/script"
TIMEOUT_SEC = 2            # Moonraker request timeout
FALLBACK_MSG = "IP NOT FOUND"

def _ip_from_socket_probe() -> Union[str, None]:
    """Fast method: use a dummy UDP connect to infer the routable IP."""
    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        # 192.0.2.0/24 is TEST-NET-1 (non-routable); no packet is sent.
        sock.connect(("192.0.2.1", 1))
        ip = sock.getsockname()[0]
        sock.close()
        if not ip.startswith("127."):
            return ip
    except Exception:
        pass
    return None


def _ip_from_ifaces() -> Union[str, None]:
    """
    Fallback: iterate over network interfaces and return
    the first non-loopback IPv4 address.
    """
    try:
        # Standard Linux ioctl SIOCGIFCONF approach
        max_bytes = 8096
        sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        names = array('B', b'\0' * max_bytes)
        bytelen = struct.unpack('iL',
                                fcntl.ioctl(sock.fileno(),
                                            0x8912,  # SIOCGIFCONF
                                            struct.pack('iL', max_bytes, names.buffer_info()[0])
                                            ))[0]
        sock.close()
        namestr = names.tobytes()
        for i in range(0, bytelen, 40):
            iface_name = namestr[i:i+16].split(b'\0', 1)[0].decode()
            ip_bytes = namestr[i+20:i+24]
            ip_addr = socket.inet_ntoa(ip_bytes)
            if not ip_addr.startswith("127."):
                return ip_addr
    except Exception:
        pass
    return None


def get_ip_address() -> Union[str, None]:
    """Return the first non-loopback IPv4 address or None if none found."""
    return _ip_from_socket_probe() or _ip_from_ifaces()


def send_to_moonraker(message: str) -> None:
    """Send an M117 message to Moonraker."""
    payload = {"command": "printer.gcode.script",
               "script": f"M117 {message}"}
    try:
        r = requests.post(MOONRAKER_API, json=payload, timeout=TIMEOUT_SEC)
        r.raise_for_status()
        print(f"Sent to Moonraker: {message}")
    except Exception as exc:
        print(f"Error sending to Moonraker: {exc}", file=sys.stderr)


def main() -> None:
    ip = get_ip_address()
    if ip:
        send_to_moonraker(ip)
    else:
        send_to_moonraker(FALLBACK_MSG)


if __name__ == "__main__":
    main()
