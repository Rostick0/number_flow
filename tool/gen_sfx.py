import math, struct, wave, sys, random
RATE = 22050
out = sys.argv[1]

def tone(freq, dur, vol=0.5, attack=0.005, decay=None, freq_end=None, harmonics=((1,1.0),), noise=0.0):
    n = int(RATE*dur); s=[]; phase=0.0
    decay = decay or dur
    for i in range(n):
        t = i/RATE
        f = freq if freq_end is None else freq + (freq_end-freq)*(t/dur)
        phase += 2*math.pi*f/RATE
        env = min(1.0, t/attack) * math.exp(-t*4.0/decay)
        v = sum(a*math.sin(phase*h) for h,a in harmonics)
        if noise: v += noise*(random.random()*2-1)
        s.append(v*env*vol)
    return s

def seq(*parts, gap=0.0):
    r=[]
    for p in parts:
        r += p + [0.0]*int(RATE*gap)
    return r

def mix(a, b, offset=0.0):
    o=int(RATE*offset); n=max(len(a), o+len(b)); r=[0.0]*n
    for i,v in enumerate(a): r[i]+=v
    for i,v in enumerate(b): r[o+i]+=v
    return r

def save(name, samples):
    peak = max(1e-9, max(abs(x) for x in samples))
    k = min(1.0, 0.9/peak)
    with wave.open(f"{out}/{name}.wav", 'wb') as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(RATE)
        w.writeframes(b''.join(struct.pack('<h', int(max(-1,min(1,x*k))*32767)) for x in samples))

soft = ((1,1.0),(2,0.25),(3,0.08))
random.seed(7)
save('spawn',   [x*0.35 for x in tone(660, 0.09, freq_end=880, harmonics=soft)])
save('move',    [x*0.4 for x in tone(420, 0.06, freq_end=360, harmonics=((1,1.0),), noise=0.08)])
save('merge',   mix(tone(523.25, 0.16, harmonics=soft), tone(783.99, 0.22, harmonics=soft), 0.06))
save('combo',   mix(mix(tone(523.25,0.14,harmonics=soft), tone(659.25,0.14,harmonics=soft),0.06), tone(1046.5,0.3,harmonics=soft),0.12))
save('reward',  mix(mix(tone(1318.5,0.12,harmonics=soft), tone(1567.98,0.12,harmonics=soft),0.07), tone(2093,0.35,harmonics=soft),0.14))
save('gameover',mix(mix(tone(392,0.25,harmonics=soft), tone(329.63,0.25,harmonics=soft),0.18), tone(261.63,0.6,harmonics=soft),0.36))
save('invalid', [x*0.4 for x in tone(180, 0.08, harmonics=((1,1.0),(3,0.3)))])
save('levelup', mix(mix(tone(587.33,0.12,harmonics=soft), tone(739.99,0.12,harmonics=soft),0.08), tone(880,0.3,harmonics=soft),0.16))
