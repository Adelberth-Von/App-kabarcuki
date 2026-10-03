"""Generate abc's original, short pixel chime. Standard-library PCM WAV."""
from pathlib import Path
import math, struct, wave

rate = 22050
duration = 1.08
notes = [(0.04, 523.251, 0.25), (0.27, 659.255, 0.25), (0.50, 783.991, 0.48)]
samples = []
for i in range(round(rate * duration)):
    t = i / rate
    value = 0.0
    for start, frequency, length in notes:
        local = t - start
        if 0 <= local < length:
            envelope = min(1, local / 0.012) * min(1, (length - local) / 0.055) * math.exp(-3.2 * local)
            # A softened pulse timbre keeps the pixel character without sharp edges.
            tone = math.sin(2 * math.pi * frequency * local) + 0.16 * math.sin(6 * math.pi * frequency * local)
            value += 0.27 * envelope * tone
    samples.append(round(max(-1, min(1, value)) * 32767))
target = Path(__file__).resolve().parents[1] / 'res/raw/abc_chime.wav'
target.parent.mkdir(parents=True, exist_ok=True)
with wave.open(str(target), 'wb') as out:
    out.setnchannels(1)
    out.setsampwidth(2)
    out.setframerate(rate)
    out.writeframes(struct.pack('<' + 'h' * len(samples), *samples))
print(f'abc chime: {duration:.2f}s, mono PCM, {rate}Hz')
