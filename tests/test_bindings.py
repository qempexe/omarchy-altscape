"""Exercise managed binding upgrades without touching the desktop config."""
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

HELPER = Path(__file__).resolve().parents[1] / "bin/altscape-binds"
PLUGIN = "io.github.qempexe.altscape"


class Bindings(unittest.TestCase):
    def check_format(self, suffix, shortcut):
        with tempfile.TemporaryDirectory() as temporary:
            home = Path(temporary)
            config = home / f".config/hypr/hyprland.{suffix}"
            config.parent.mkdir(parents=True)
            config.write_text("-- personal config\n" if suffix == "lua" else "# personal config\n")
            if suffix == "conf":
                config = config.with_name("bindings.conf")
                config.write_text("# personal config\n")
            original = config.read_text()
            # Isolate both config writes and compositor IPC.
            binary = home / "bin"
            binary.mkdir()
            mock = binary / "hyprctl"
            mock.write_text('#!/bin/sh\nif [ "$1" = "-j" ]; then echo \'[{"key":"TAB","modmask":8,"arg":"' + PLUGIN + '"},{"key":"TAB","modmask":64,"arg":"' + PLUGIN + '"}]\'; fi\n')
            mock.chmod(0o755)
            environment = dict(os.environ, HOME=str(home), PATH=f"{binary}:{os.environ['PATH']}")

            def run(*args):
                return json.loads(subprocess.check_output([str(HELPER), *args],
                                                         env=environment, text=True))

            # Start from the old exec transport, as existing installations do.
            begin, end = ("-- >>> altscape >>>", "-- <<< altscape <<<") if suffix == "lua" else ("# >>> altscape >>>", "# <<< altscape <<<")
            config.write_text(original + f"\n{begin}\nold exec binding\n{end}\n")
            self.assertTrue(run("sync", shortcut)["ok"])
            generated = config.read_text()
            self.assertNotIn("old exec binding", generated)
            self.assertTrue(generated.startswith(original))
            modifier = shortcut.upper()
            if suffix == "lua":
                self.assertIn(f'hl.dsp.global("{PLUGIN}:next")', generated)
                self.assertIn(f'hl.dsp.global("{PLUGIN}:prev")', generated)
                for side in ("L", "R"):
                    self.assertIn(f'{modifier} + {modifier}_{side}', generated)
                self.assertEqual(generated.count("release = true, transparent = true, ignore_mods = true, non_consuming = true"), 2)
                self.assertIn('hl.layer_rule({ match = { namespace = "^altscape$" }, no_anim = true, animation = "none" })', generated)
            else:
                self.assertIn(f'bind = {modifier}, TAB, global, {PLUGIN}:next', generated)
                self.assertIn(f'bind = {modifier} SHIFT, TAB, global, {PLUGIN}:prev', generated)
                for side in ("L", "R"):
                    self.assertIn(f'bindrint = {modifier}, {modifier}_{side}, global, {PLUGIN}:release', generated)
                self.assertIn("layerrule = noanim, ^altscape$", generated)
            self.assertFalse(run("sync", shortcut)["changed"])
            self.assertEqual(run("status")["shortcut"], shortcut)
            run("sync", "off")
            self.assertNotIn(f"{PLUGIN}:next", config.read_text())
            run("remove")
            self.assertEqual(config.read_text().strip(), original.strip())

    def test_lua_alt(self):
        self.check_format("lua", "alt")

    def test_lua_super(self):
        self.check_format("lua", "super")

    def test_conf_alt(self):
        self.check_format("conf", "alt")

    def test_conf_super(self):
        self.check_format("conf", "super")


if __name__ == "__main__":
    unittest.main()
