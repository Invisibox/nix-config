"""Apply declared settings while preserving Neiro's writable listening state."""

import json
import os
from pathlib import Path
import sys
import tempfile

import tomlkit


def merge_state(state_path, settings):
    state = tomlkit.parse(state_path.read_text()) if state_path.exists() else {"bypass": False}
    state.update(settings)
    # Parse and serialise before touching the existing state.
    content = tomlkit.dumps(state)
    state_path.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(mode="w", dir=state_path.parent, delete=False) as temporary:
        temporary.write(content)
    os.replace(temporary.name, state_path)


if __name__ == "__main__":
    config_home = Path(os.environ.get("XDG_CONFIG_HOME") or Path.home() / ".config")
    merge_state(config_home / "neiro/state.toml", json.loads(Path(sys.argv[1]).read_text()))
