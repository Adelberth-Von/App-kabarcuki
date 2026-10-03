"""Fail if optimization removes or changes the notification sound in a release APK."""
import argparse
import hashlib
import io
import json
from pathlib import Path
import struct
import wave
import zipfile


def class_definitions(raw):
    string_offset = struct.unpack_from('<I', raw, 60)[0]
    type_offset = struct.unpack_from('<I', raw, 68)[0]
    count, offset = struct.unpack_from('<II', raw, 96)
    names = set()
    for i in range(count):
        type_index = struct.unpack_from('<I', raw, offset + i * 32)[0]
        string_index = struct.unpack_from('<I', raw, type_offset + type_index * 4)[0]
        start = struct.unpack_from('<I', raw, string_offset + string_index * 4)[0]
        while raw[start] & 128:
            start += 1
        start += 1
        names.add(raw[start:raw.index(0, start)].decode('utf-8', errors='replace'))
    return names


def verify(apk):
    original = (Path(__file__).resolve().parent.parent / 'res/raw/abc_chime.wav').read_bytes()
    with zipfile.ZipFile(apk) as archive:
        assert archive.testzip() is None, 'Corrupt APK'
        # AAPT may shorten resource filenames, so inspect the actual bytes.
        matches = [name for name in archive.namelist()
                   if name.startswith('res/') and archive.read(name) == original]
        assert len(matches) == 1, 'Release APK must contain the original chime exactly once'
        with wave.open(io.BytesIO(archive.read(matches[0]))) as sound:
            assert sound.getnchannels() == 1 and sound.getsampwidth() == 2
            assert sound.getframerate() == 22050
            duration = sound.getnframes() / sound.getframerate()
            assert 0.9 < duration < 1.2
        classes = set()
        for name in archive.namelist():
            if name.startswith('classes') and name.endswith('.dex'):
                classes.update(class_definitions(archive.read(name)))
        assert not classes.intersection({'Lid/kabar/app/QaProbe;', 'Lid/kabar/app/DeviceQA;'})
    print(json.dumps({'release_assets_verified': True, 'sound_resource_file': matches[0],
                      'sound_duration_seconds': duration, 'debug_classes_absent': True,
                      'apk_sha256': hashlib.sha256(Path(apk).read_bytes()).hexdigest()}))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('apk', type=Path)
    verify(parser.parse_args().apk)
