"""Restore versioned original GLBs and the editable Blender ZIP before importing Godot."""
from pathlib import Path
import gzip
import hashlib
import json

ROOT = Path(__file__).resolve().parents[1]

def checked_write(path, data, expected):
    if hashlib.sha256(data).hexdigest() != expected:
        raise RuntimeError(f'Asset checksum mismatch: {path}')
    destination = ROOT / path
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_bytes(data)


def main():
    manifest = json.loads((ROOT / 'art/asset-manifest.json').read_text())
    for model in manifest['models']:
        checked_write(model['path'], gzip.decompress((ROOT / model['packed']).read_bytes()), model['sha256'])
    source = manifest['source_zip']
    checked_write('art/Aurora_Source.blend.zip', b''.join((ROOT / part).read_bytes() for part in source['parts']), source['sha256'])
    print(f"AURORA_ASSETS_RESTORED: {len(manifest['models'])} models and editable Blender ZIP")


if __name__ == '__main__':
    main()
