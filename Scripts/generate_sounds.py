#!/usr/bin/env python3
"""Synthesize bundled drumroll and fanfare WAVs."""

from __future__ import annotations

import math
import random
import struct
import wave
from pathlib import Path

RATE = 44100


def clamp(value: float) -> float:
    return max(-1.0, min(1.0, value))


def write_wav(path: Path, frames: list[tuple[float, float]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(path), "w") as handle:
        handle.setnchannels(2)
        handle.setsampwidth(2)
        handle.setframerate(RATE)
        packed = bytearray()
        for left, right in frames:
            packed += struct.pack(
                "<hh",
                int(clamp(left) * 32767),
                int(clamp(right) * 32767),
            )
        handle.writeframes(packed)


def exp_decay(t: float, life: float) -> float:
    if t < 0 or t > life:
        return 0.0
    return math.exp(-4.8 * t / life)


def snare_hit(t: float, rng: random.Random) -> float:
    if t < 0 or t > 0.09:
        return 0.0
    noise = rng.uniform(-1.0, 1.0)
    body = math.sin(2 * math.pi * 190 * t) * math.exp(-28 * t)
    crack = math.sin(2 * math.pi * 340 * t) * math.exp(-42 * t)
    wires = noise * math.exp(-38 * t)
    return (0.38 * body) + (0.22 * crack) + (0.55 * wires)


def make_drumroll(seconds: float = 5.0) -> list[tuple[float, float]]:
    n = int(RATE * seconds)
    samples = [0.0] * n
    rng = random.Random(7)

    hits: list[float] = []
    t = 0.012
    while t < seconds - 0.04:
        progress = t / seconds
        interval = 0.118 - (0.082 * (progress**1.15))
        hits.append(t)
        t += max(0.028, interval)

    for start in hits:
        progress = start / seconds
        gain = 0.42 + (0.58 * (progress**0.85))
        pan = rng.uniform(-0.18, 0.18)
        length = int(0.09 * RATE)
        origin = int(start * RATE)
        hit_rng = random.Random(origin)
        for i in range(length):
            idx = origin + i
            if idx >= n:
                break
            samples[idx] += snare_hit(i / RATE, hit_rng) * gain * (1.0 + pan * 0.15)

    # Slight room tail so the roll feels bigger.
    frames: list[tuple[float, float]] = []
    delay = int(0.018 * RATE)
    for i, sample in enumerate(samples):
        echo = samples[i - delay] * 0.18 if i >= delay else 0.0
        wet = clamp(sample + echo)
        left = wet * 0.96
        right = wet * 1.0
        frames.append((left, right))
    return frames


def brass_tone(freq: float, t: float, life: float) -> float:
    if t < 0 or t > life:
        return 0.0
    attack = min(1.0, t / 0.012)
    env = attack * exp_decay(t, life)
    # Bright brass-ish stack: saw-ish harmonics with a little growl.
    wave = (
        math.sin(2 * math.pi * freq * t)
        + 0.45 * math.sin(2 * math.pi * freq * 2 * t)
        + 0.22 * math.sin(2 * math.pi * freq * 3 * t)
        + 0.12 * math.sin(2 * math.pi * freq * 4 * t)
        + 0.06 * math.sin(2 * math.pi * freq * 6 * t)
    )
    vibrato = 1.0 + 0.006 * math.sin(2 * math.pi * 5.2 * t)
    return wave * env * vibrato * 0.22


def noise_burst(t: float, life: float, rng: random.Random) -> float:
    if t < 0 or t > life:
        return 0.0
    return rng.uniform(-1.0, 1.0) * math.exp(-5.5 * t / life)


def make_fanfare(seconds: float = 3.2) -> list[tuple[float, float]]:
    n = int(RATE * seconds)
    left = [0.0] * n
    right = [0.0] * n
    rng = random.Random(21)

    def add(start: float, freq: float, life: float, gain: float, pan: float = 0.0) -> None:
        origin = int(start * RATE)
        length = int(life * RATE)
        for i in range(length):
            idx = origin + i
            if idx >= n:
                break
            sample = brass_tone(freq, i / RATE, life) * gain
            left[idx] += sample * (1.0 - pan)
            right[idx] += sample * (1.0 + pan)

    # Timpani / orchestra boom
    for i in range(int(1.1 * RATE)):
        t = i / RATE
        boom = (
            math.sin(2 * math.pi * 73 * t)
            + 0.55 * math.sin(2 * math.pi * 98 * t)
            + 0.22 * math.sin(2 * math.pi * 146 * t)
        ) * math.exp(-3.4 * t)
        left[i] += boom * 0.38
        right[i] += boom * 0.38

    # Crash
    crash_len = int(1.6 * RATE)
    for i in range(crash_len):
        t = i / RATE
        crash = noise_burst(t, 1.6, rng) * (0.55 if t < 0.03 else 0.28)
        left[i] += crash * 0.42
        right[i] += crash * 0.48

    # Rising brass hits
    add(0.00, 261.63, 1.4, 1.15, -0.15)  # C4
    add(0.00, 329.63, 1.4, 1.05, 0.05)   # E4
    add(0.00, 392.00, 1.5, 1.10, 0.15)   # G4
    add(0.18, 523.25, 1.6, 1.20, -0.08)  # C5
    add(0.34, 659.25, 1.5, 1.05, 0.12)   # E5
    add(0.48, 783.99, 1.7, 1.15, 0.00)   # G5

    # Big final chord
    for freq, gain, pan in (
        (130.81, 1.25, 0.00),
        (196.00, 1.05, -0.10),
        (261.63, 1.20, 0.08),
        (329.63, 1.10, -0.12),
        (392.00, 1.15, 0.12),
        (523.25, 1.25, 0.00),
        (659.25, 0.90, 0.16),
        (1046.50, 0.55, -0.05),
    ):
        add(0.62, freq, 2.4, gain, pan)

    frames: list[tuple[float, float]] = []
    peak = 1e-6
    for l, r in zip(left, right):
        peak = max(peak, abs(l), abs(r))
    norm = 0.92 / peak
    for l, r in zip(left, right):
        frames.append((l * norm, r * norm))
    return frames


def main() -> None:
    root = Path(__file__).resolve().parents[1] / "Resources"
    write_wav(root / "drumroll.wav", make_drumroll(5.0))
    write_wav(root / "fanfare.wav", make_fanfare(3.2))
    print(f"Wrote {root / 'drumroll.wav'}")
    print(f"Wrote {root / 'fanfare.wav'}")


if __name__ == "__main__":
    main()
