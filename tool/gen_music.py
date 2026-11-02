"""Synthesizes the calm background tracks (own work, no third-party samples).

Usage: python3 tool/gen_music.py assets/music
Needs numpy and ffmpeg (for MP3 encoding).
"""
import os, subprocess, sys, wave
import numpy as np

RATE = 44100
out = sys.argv[1]


def midi(n):
    return 440.0 * 2 ** ((n - 69) / 12)


def env(n, attack, release, total=None):
    """Linear attack, sustain, cosine release over n samples."""
    e = np.ones(n)
    a = min(n, int(attack * RATE))
    r = min(n - a, int(release * RATE))
    if a: e[:a] = np.linspace(0, 1, a)
    if r: e[n - r:] *= 0.5 + 0.5 * np.cos(np.linspace(0, np.pi, r))
    return e


def pad(freq, dur, rng, bright=0.5):
    """Soft additive pad: a few detuned voices with gently breathing harmonics."""
    n = int(dur * RATE); t = np.arange(n) / RATE
    l = np.zeros(n); r = np.zeros(n)
    for detune, pan in ((-0.07, 0.2), (0.0, 0.5), (0.07, 0.8)):
        f = freq * 2 ** (detune / 12)
        ph = rng.uniform(0, 2 * np.pi)
        lfo = 0.5 + 0.5 * np.sin(2 * np.pi * rng.uniform(0.05, 0.12) * t + ph)
        v = np.zeros(n)
        for h in range(1, 7):
            if f * h > 5000: break
            amp = (1 / h ** 1.6) * (1 if h == 1 else bright * (0.6 + 0.4 * lfo))
            v += amp * np.sin(2 * np.pi * f * h * t + ph * h)
        l += v * (1 - pan); r += v * pan
    e = env(n, dur * 0.35, dur * 0.4)
    return l * e, r * e


def bell(freq, dur):
    """Glassy bell: inharmonic partials with fast-decaying highs."""
    n = int(dur * RATE); t = np.arange(n) / RATE
    v = np.zeros(n)
    for ratio, amp, decay in ((1, 1.0, 1.6), (2.0, 0.35, 0.9), (2.76, 0.2, 0.6), (5.4, 0.08, 0.25)):
        v += amp * np.sin(2 * np.pi * freq * ratio * t) * np.exp(-t / decay)
    return v * env(n, 0.004, 0.3)


def kalimba(freq, dur):
    n = int(dur * RATE); t = np.arange(n) / RATE
    v = np.sin(2 * np.pi * freq * t) * np.exp(-t / 0.9)
    v += 0.25 * np.sin(2 * np.pi * freq * 5.95 * t) * np.exp(-t / 0.08)
    v += 0.1 * np.sin(2 * np.pi * freq * 2 * t) * np.exp(-t / 0.4)
    return v * env(n, 0.003, 0.2)


def epiano(freq, dur):
    """Two-operator FM with a decaying index: a soft Rhodes-like tine."""
    n = int(dur * RATE); t = np.arange(n) / RATE
    index = 1.6 * np.exp(-t / 0.35)
    v = np.sin(2 * np.pi * freq * t + index * np.sin(2 * np.pi * freq * t))
    return v * np.exp(-t / 1.8) * env(n, 0.006, 0.4)


def bass(freq, dur):
    n = int(dur * RATE); t = np.arange(n) / RATE
    v = np.sin(2 * np.pi * freq * t) + 0.15 * np.sin(4 * np.pi * freq * t)
    return v * env(n, 0.8, dur * 0.5)


def waves(dur, rng):
    """Very quiet filtered noise that swells like distant surf."""
    n = int(dur * RATE); t = np.arange(n) / RATE
    spec = np.fft.rfft(rng.standard_normal(n))
    f = np.fft.rfftfreq(n, 1 / RATE)
    spec *= 1 / (1 + (f / 400) ** 2)
    v = np.fft.irfft(spec, n)
    v /= np.abs(v).max()
    swell = (0.5 + 0.5 * np.sin(2 * np.pi * t / 9.0 - np.pi / 2)) ** 2
    return v * swell


def reverb(x, rng, seconds=3.5, damp=2500):
    """Convolution with a decaying, darkened noise tail."""
    n = int(seconds * RATE); t = np.arange(n) / RATE
    ir = rng.standard_normal(n) * np.exp(-t * 6.9 / seconds)
    spec = np.fft.rfft(ir)
    f = np.fft.rfftfreq(n, 1 / RATE)
    ir = np.fft.irfft(spec / (1 + (f / damp) ** 2), n)
    ir /= np.sqrt((ir ** 2).sum())
    size = 1 << int(np.ceil(np.log2(len(x) + n)))
    y = np.fft.irfft(np.fft.rfft(x, size) * np.fft.rfft(ir, size), size)
    return y[:len(x)]


def add(buf, sig, at, pan=0.5, gain=1.0):
    i = int(at * RATE)
    if i >= buf.shape[1]: return
    if isinstance(sig, tuple):
        sl, sr = sig
    else:
        sl, sr = sig * (1 - pan) * 2, sig * pan * 2
    m = min(len(sl), buf.shape[1] - i)
    buf[0, i:i + m] += sl[:m] * gain
    buf[1, i:i + m] += sr[:m] * gain


def compose(name, *, seed, root, chords, scale, bpm, bars_per_chord, cycles,
            lead, lead_gain, density, bass_gain=0.25, waves_gain=0.0, bright=0.5):
    rng = np.random.default_rng(seed)
    beat = 60 / bpm
    chord_len = bars_per_chord * 4 * beat
    total = chord_len * len(chords) * cycles + 6
    buf = np.zeros((2, int(total * RATE)))
    lead_buf = np.zeros_like(buf)

    # Melody notes come from the scale over two octaves, moving mostly by step.
    notes = sorted({root + 12 + o * 12 + s for o in (0, 1) for s in scale})
    idx = len(notes) // 2

    for c in range(cycles):
        for k, chord in enumerate(chords):
            at = (c * len(chords) + k) * chord_len
            for j, iv in enumerate(chord):
                add(buf, pad(midi(root + iv), chord_len + 2.5, rng, bright), at, gain=0.09)
            add(buf, bass(midi(root - 12 + chord[0]), chord_len + 1.0), at, gain=bass_gain)

            # First and last cycles stay sparse so tracks breathe in and out.
            d = density * (0.35 if c in (0, cycles - 1) else 1.0)
            steps = bars_per_chord * 8
            for s in range(steps):
                if rng.random() > d * (1.4 if s % 4 == 0 else 0.7): continue
                idx = int(np.clip(idx + rng.choice([-2, -1, -1, 0, 1, 1, 2]), 0, len(notes) - 1))
                note = notes[idx]
                # Prefer chord tones on strong steps.
                if s % 4 == 0:
                    tones = [n for n in notes if (n - root) % 12 in {iv % 12 for iv in chord}]
                    note = min(tones, key=lambda n: abs(n - note))
                    idx = notes.index(note)
                when = at + s * beat / 2 + rng.normal(0, 0.012)
                vel = rng.uniform(0.6, 1.0)
                add(lead_buf, lead(midi(note), 4.0), max(0, when),
                    pan=rng.uniform(0.3, 0.7), gain=lead_gain * vel)

    if waves_gain:
        w = waves(total, rng)
        add(buf, (w, np.roll(w, int(0.31 * RATE))), 0, gain=waves_gain)

    mix = buf + lead_buf
    wet = np.stack([reverb(mix[0], rng), reverb(mix[1], rng)])
    mix = mix * 0.65 + wet * 0.55

    n = mix.shape[1]
    mix *= env(n, 4.0, 6.0)
    mix = np.tanh(mix * 1.2) / np.tanh(1.2)
    mix *= 0.8 / max(1e-9, np.abs(mix).max())

    wav = f"{out}/{name}.wav"
    with wave.open(wav, 'wb') as w:
        w.setnchannels(2); w.setsampwidth(2); w.setframerate(RATE)
        w.writeframes((mix.T * 32767).astype('<i2').tobytes())
    subprocess.run(['ffmpeg', '-y', '-loglevel', 'error', '-i', wav,
                    '-codec:a', 'libmp3lame', '-b:a', '96k', f"{out}/{name}.mp3"], check=True)
    os.remove(wav)
    print(f"{name}: {n / RATE:.0f}s")


MAJ_PENTA = (0, 2, 4, 7, 9)
MIN_PENTA = (0, 3, 5, 7, 10)

os.makedirs(out, exist_ok=True)

# C major: Cmaj9 – Am7 – Fmaj7 – G6sus
compose('drift', seed=11, root=48, bpm=62, bars_per_chord=2, cycles=5,
        chords=[(0, 7, 11, 14), (-3, 4, 7, 12), (-7, 4, 9, 12), (-5, 2, 7, 9)],
        scale=MAJ_PENTA, lead=bell, lead_gain=0.22, density=0.18)

# D dorian: Dm9 – G9 – Bbmaj7 – C6
compose('tide', seed=23, root=50, bpm=58, bars_per_chord=2, cycles=5,
        chords=[(0, 7, 10, 15), (5, 9, 12, 17), (-4, 3, 7, 12), (-2, 5, 7, 10)],
        scale=MIN_PENTA, lead=epiano, lead_gain=0.2, density=0.2, waves_gain=0.05, bright=0.35)

# F lydian: Fmaj7#11 – Gadd9/F – Em7 – Am7
compose('glow', seed=37, root=53, bpm=70, bars_per_chord=2, cycles=5,
        chords=[(0, 7, 11, 16), (2, 9, 14, 18), (-1, 6, 9, 14), (-8, 4, 7, 11)],
        scale=(0, 2, 4, 7, 11), lead=kalimba, lead_gain=0.28, density=0.3, bright=0.6)

# A minor: Am9 – Fmaj7 – Cadd9 – Em7
compose('mist', seed=41, root=45, bpm=54, bars_per_chord=2, cycles=4,
        chords=[(0, 7, 12, 14), (-4, 3, 7, 12), (3, 10, 14, 19), (-5, 7, 10, 14)],
        scale=MIN_PENTA, lead=bell, lead_gain=0.18, density=0.14, waves_gain=0.07, bright=0.3)
