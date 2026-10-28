"""Live regression test: real Hyprland global shortcuts and Altscape overlay.

Requires an unlocked Hyprland/Omarchy session. Dummy windows are used; no real
window is focused or closed. The overlay may briefly appear during the test.
"""
import json
import os
from pathlib import Path
import subprocess
import tempfile
import time
import unittest

REPO = Path(__file__).resolve().parents[1]


class Shortcuts(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.temp = tempfile.TemporaryDirectory(prefix="altscape-shortcuts-")
        cls.addClassCleanup(cls.temp.cleanup)
        directory = Path(cls.temp.name)
        omarchy = Path(os.environ.get("OMARCHY_PATH", "/usr/share/omarchy"))
        (directory / "Commons").symlink_to(omarchy / "shell/Commons")
        cls.config = directory / "shell.qml"
        cls.appid = f"altscape-test-{os.getpid()}"
        cls.config.write_text((REPO / "tests/shortcuts.qml.in").read_text()
                              .replace("@REPO@", REPO.as_uri()).replace("@APPID@", cls.appid))
        cls.keys = dict(next="F33", prev="F34", release="F35")
        binds = json.loads(subprocess.check_output(["hyprctl", "-j", "binds"], text=True))
        if any(b.get("key", "").upper() in cls.keys.values() for b in binds):
            raise unittest.SkipTest("F33–F35 must be unused for this test")
        # wtype uses a generated keymap rather than hardware keycodes.
        original = "bool: true" in subprocess.check_output(
            ["hyprctl", "getoption", "input:resolve_binds_by_sym"], text=True)
        cls.addClassCleanup(cls.resolve_symbols, original)
        cls.resolve_symbols(True)
        for action, key in cls.keys.items():
            options = "release = true, transparent = true, ignore_mods = true, non_consuming = true" if action == "release" else ""
            subprocess.run(["hyprctl", "eval",
                            f'hl.bind("{key}", hl.dsp.global("{cls.appid}:{action}"), {{{options}}})'],
                           capture_output=True, check=True)
            cls.addClassCleanup(subprocess.run,
                                ["hyprctl", "eval", f'hl.unbind("{key}")'],
                                capture_output=True, check=True)
        # Exercise real modifier/Tab key-up ordering as well as action events.
        cls.real_modifier = not any(
            not b.get("submap") and ((b.get("modmask") in (4, 5) and b.get("key", "").upper() == "TAB")
            or b.get("key", "").upper() == "CONTROL_L") for b in binds)
        if cls.real_modifier:
            for key, action in (("CTRL + TAB", "next"), ("CTRL + SHIFT + TAB", "prev"),
                                ("CTRL + CONTROL_L", "release")):
                options = "release = true, transparent = true, ignore_mods = true, non_consuming = true" if action == "release" else ""
                subprocess.run(["hyprctl", "eval",
                                f'hl.bind("{key}", hl.dsp.global("{cls.appid}:{action}"), {{{options}}})'],
                               capture_output=True, check=True)
                cls.addClassCleanup(subprocess.run,
                                    ["hyprctl", "eval", f'hl.unbind("{key}")'],
                                    capture_output=True, check=True)
        cls.log = (directory / "shell.log").open("w+")
        cls.process = subprocess.Popen(["qs", "-p", str(cls.config), "--no-color"],
                                       stdout=cls.log, stderr=subprocess.STDOUT)
        cls.addClassCleanup(cls.stop_shell)
        for _ in range(100):
            if cls.process.poll() is not None:
                cls.log.seek(0)
                raise RuntimeError(cls.log.read())
            result = cls.ipc("state", check=False)
            if result.returncode == 0 and result.stdout.startswith("{"):
                return
            time.sleep(.05)
        raise RuntimeError("Test shell did not become ready")

    @classmethod
    def stop_shell(cls):
        cls.ipc("quit", check=False)
        try:
            cls.process.wait(timeout=5)
        except subprocess.TimeoutExpired:
            cls.process.terminate()
            cls.process.wait(timeout=5)
        cls.log.seek(0)
        log = cls.log.read()
        cls.log.close()
        if "TypeError" in log or "ReferenceError" in log:
            raise AssertionError(log)

    @staticmethod
    def resolve_symbols(enabled):
        subprocess.run(["hyprctl", "eval",
                        "hl.config({input = {resolve_binds_by_sym = "
                        + str(enabled).lower() + "}})"], capture_output=True, check=True)

    @classmethod
    def ipc(cls, method, *args, check=True):
        return subprocess.run(["qs", "ipc", "-p", str(cls.config), "call", "test", method, *args],
                              text=True, capture_output=True, check=check, timeout=5)

    def state(self):
        return json.loads(self.ipc("state").stdout)

    def assert_hidden(self):
        deadline = time.monotonic() + 2
        while time.monotonic() < deadline:
            visual = json.loads(self.ipc("visualState").stdout)
            if not visual["shown"]:
                return
            time.sleep(.02)
        self.fail(f"Switcher is still visible: {visual}")

    def send(self, *actions):
        # Real key press/release events, without artificial delays. Dispatching
        # hl.dsp.global through hyprctl alone only sends a press, not a release.
        args = ["wtype"]
        for action in actions:
            args += ["-k", self.keys[action]]
        self.send_keys(*args[1:])

    def send_keys(self, *args):
        subprocess.run(["wtype", *args], capture_output=True, check=True)
        time.sleep(.03)

    def setUp(self):
        self.ipc("reset", "true")

    def test_fast_tap(self):
        self.send("next", "release")
        self.assertEqual(self.state(), dict(opened=False, selected=1, count=1, focused="0xb"))

    def test_animated_fast_tap(self):
        self.ipc("effects")
        self.send("next", "release")
        self.assert_hidden()
        self.assertEqual(self.state()["count"], 1)

    def test_modifier_and_tab_release_orders(self):
        if not self.real_modifier:
            self.skipTest("Ctrl+Tab and Ctrl release bindings must be unused")
        for modifier_first in (False, True):
            for delay in (1, 10):
                with self.subTest(modifier_first=modifier_first, delay=delay):
                    self.ipc("reset", "true")
                    self.ipc("effects")
                    keys = ["-M", "ctrl", "-P", "Control_L", "-P", "Tab", "-s", str(delay)]
                    if modifier_first:
                        keys += ["-p", "Control_L", "-m", "ctrl", "-p", "Tab"]
                    else:
                        keys += ["-p", "Tab", "-p", "Control_L", "-m", "ctrl"]
                    self.send_keys(*keys)
                    self.assert_hidden()
                    self.assertEqual(self.state()["count"], 1)

    def test_hold_and_cycle(self):
        self.send("next")
        self.assertEqual(self.state(), dict(opened=True, selected=1, count=0, focused=""))
        self.send("next", "release")
        self.assertEqual(self.state(), dict(opened=False, selected=2, count=1, focused="0xc"))

    def test_reverse_tap(self):
        self.send("prev", "release")
        self.assertEqual(self.state(), dict(opened=False, selected=2, count=1, focused="0xc"))

    def test_repeated_fast_taps(self):
        self.send(*(["next", "release"] * 50))
        self.assertEqual(self.state(), dict(opened=False, selected=1, count=50, focused="0xb"))

    def test_release_after_other_keys(self):
        # A release binding must survive being held while Tab is pressed.
        self.send_keys("-P", "F35", "-k", "F33", "-p", "F35")
        self.assertEqual(self.state(), dict(opened=False, selected=1, count=1, focused="0xb"))

    def test_release_with_shift_still_down(self):
        # ignore_mods keeps release working when Shift outlives the modifier.
        self.send_keys("-P", "F35", "-k", "F33", "-M", "shift", "-p", "F35", "-m", "shift")
        self.assertEqual(self.state(), dict(opened=False, selected=1, count=1, focused="0xb"))

    def test_duplicate_release(self):
        self.send("next", "release", "release")
        self.assertEqual(self.state()["count"], 1)
        self.assertFalse(self.state()["opened"])

    def test_release_without_open(self):
        self.send("release")
        self.assertEqual(self.state()["count"], 0)
        self.assertFalse(self.state()["opened"])

    def test_manual_open_ignores_release(self):
        self.ipc("open")
        self.send("release")
        self.assertTrue(self.state()["opened"])
        self.assertEqual(self.state()["count"], 0)

    def test_switch_on_release_disabled(self):
        self.ipc("reset", "false")
        self.send("next", "release")
        self.assertTrue(self.state()["opened"])
        self.assertEqual(self.state()["count"], 0)


if __name__ == "__main__":
    unittest.main()
