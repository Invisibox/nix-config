import stat
from pathlib import Path
import tempfile
import unittest

import tomlkit

from merge_state import merge_state


class MergeStateTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.state = Path(self.directory.name) / "neiro/state.toml"

    def test_initial_state_is_writable_and_valid(self):
        merge_state(self.state, {"speaker_sink": "alsa_output.speaker", "hw_volume": 0.8})
        saved = tomlkit.parse(self.state.read_text())
        self.assertFalse(saved["bypass"])
        self.assertEqual(saved["hw_volume"], 0.8)
        self.assertEqual(stat.S_IMODE(self.state.stat().st_mode), 0o600)

    def test_restarts_preserve_personal_eq_and_undeclared_fields(self):
        merge_state(self.state, {"hw_volume": 1.0})
        saved = tomlkit.parse(self.state.read_text())
        saved.update({"bypass": True, "profile": "music", "personal": {"enable": True, "gain_db": 2.0}})
        self.state.write_text(tomlkit.dumps(saved))
        for _ in range(2):
            merge_state(self.state, {"hw_volume": 0.8})
        saved = tomlkit.parse(self.state.read_text())
        self.assertTrue(saved["bypass"])
        self.assertEqual(saved["profile"], "music")
        self.assertEqual(saved["personal"]["gain_db"], 2.0)
        self.assertEqual(saved["hw_volume"], 0.8)

    def test_invalid_existing_state_is_not_overwritten(self):
        self.state.parent.mkdir()
        self.state.write_text("not valid TOML [")
        with self.assertRaises(tomlkit.exceptions.ParseError):
            merge_state(self.state, {"hw_volume": 0.8})
        self.assertEqual(self.state.read_text(), "not valid TOML [")


if __name__ == "__main__":
    unittest.main()
