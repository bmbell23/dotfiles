#!/usr/bin/env python3
"""Print '<pkg>\t<label>' for each package on stdin, reading the app label from the phone's APK.

Only AndroidManifest.xml and resources.arsc are streamed off the phone (adb exec-out unzip -p),
not the whole APK. Needs androguard. Usage: phone-labels.py <adb-serial> < packages
"""
import logging
import subprocess
import sys

from loguru import logger

logger.remove()
logging.disable(logging.CRITICAL)
from androguard.core.axml import ARSCParser, AXMLPrinter  # noqa: E402

ANDROID_NS = "{http://schemas.android.com/apk/res/android}"


def adb(serial, *args):
    return subprocess.run(["adb", "-s", serial, "exec-out", *args], capture_output=True, timeout=120).stdout


def label(serial, pkg):
    path = adb(serial, "pm", "path", pkg).decode(errors="replace").splitlines()
    apks = [p[8:] for p in path if p.startswith("package:")]
    base = next((p for p in apks if p.endswith("/base.apk")), apks[0] if apks else None)
    if not base:
        return None
    manifest = adb(serial, "unzip", "-p", base, "AndroidManifest.xml")
    if not manifest:
        return None
    app = AXMLPrinter(manifest).get_xml_obj().find("application")
    raw = app.get(ANDROID_NS + "label") if app is not None else None
    if not raw:
        return None
    if not raw.startswith("@"):
        return raw
    arsc = adb(serial, "unzip", "-p", base, "resources.arsc")
    if not arsc:
        return None
    res = ARSCParser(arsc)
    try:
        rid = int(raw[1:], 16)
        values = res.get_resolved_res_configs(rid)
    except Exception:
        return None
    # Prefer the default (no-qualifier) string, then any English one, then whatever exists.
    best = None
    for cfg, val in values:
        lang = cfg.get_language() if cfg else ""
        if not cfg or cfg.get_qualifier() == "":
            return val
        if best is None or lang == "en":
            best = val
    return best


def main():
    serial = sys.argv[1]
    for pkg in (line.strip() for line in sys.stdin):
        if not pkg:
            continue
        try:
            name = label(serial, pkg)
        except Exception:
            name = None
        print(f"{pkg}\t{name or ''}", flush=True)


if __name__ == "__main__":
    main()
