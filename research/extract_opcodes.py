#!/usr/bin/env python3
"""Extract the opcode name<->value table from Project Ascension's Extensions.dll.

Structure (verified, 32-bit PE32, ImageBase 0x10000000):
  GetOpcodeName(int op)  @ VA 0x102C4A93
      mov  eax, [esp+4]
      cmp  eax, 0x9D4
      ja   default
      jmp  dword ptr [eax*4 + 0x102C7AF0]     <- dense jump table, index == opcode
  Each case target is a 6-byte stub:  B8 <ptr to name string>  C3   (mov eax,str; ret)
  Unhandled opcodes jump to a stub returning the literal string "unknown".
Cross-validated: 1282/1282 names shared with TrinityCore 3.3.5 Opcodes.h have identical values.
"""
import struct, re, json, csv, sys

DLL = sys.argv[1] if len(sys.argv)>1 else "D:/Program Files/Ascension/resources/client/Extensions.dll"
OUT = sys.argv[2] if len(sys.argv)>2 else "D:/Projects/projectphoneix/research"
data = open(DLL,'rb').read()

e=struct.unpack_from('<I',data,0x3C)[0]; coff=e+4
nsec=struct.unpack_from('<H',data,coff+2)[0]; oshdr=struct.unpack_from('<H',data,coff+16)[0]
opt=coff+20; imagebase=struct.unpack_from('<I',data,opt+28)[0]
secs=[]
for i in range(nsec):
    o=opt+oshdr+i*40
    vsize,va,rawsize,rawptr=struct.unpack_from('<IIII',data,o+8)
    secs.append((va,vsize,rawptr,rawsize))
def va2off(v):
    r=v-imagebase
    for va,vs,rp,rs in secs:
        if rs and va<=r<va+rs: return rp+(r-va)
def cstr(v):
    o=va2off(v)
    if o is None: return None
    end=data.index(b'\0',o)
    return data[o:end].decode('latin1')

# --- locate the dispatcher generically: cmp eax,imm32 / ja / jmp [eax*4+tbl] ---
TBL=None; MAXOP=None
for i in range(len(data)-7):
    if data[i]==0xFF and data[i+1]==0x24 and data[i+2]==0x85:
        tbl=int.from_bytes(data[i+3:i+7],'little')
        # walk back: 0F 87 rel32 (ja), 3D imm32 (cmp eax,imm32)
        if data[i-6]==0x0F and data[i-5]==0x87 and data[i-11]==0x3D:
            n=int.from_bytes(data[i-10:i-6],'little')
            if 1000<n<70000 and va2off(tbl) is not None:
                # confirm entry 1 resolves to a B8 .. C3 stub naming a *MSG_ string
                t=int.from_bytes(data[va2off(tbl)+4:va2off(tbl)+8],'little'); to=va2off(t)
                if to and data[to]==0xB8 and data[to+5]==0xC3:
                    s=cstr(int.from_bytes(data[to+1:to+5],'little')) or ''
                    if re.match(r'^(C|S)?MSG_[A-Z0-9_]+$', s):
                        TBL, MAXOP = tbl, n; break
assert TBL, "dispatcher not found"
print("jump table VA 0x%08X, max opcode 0x%X (%d)" % (TBL, MAXOP, MAXOP))

base=va2off(TBL)
rows=[]
for op in range(0, MAXOP+1):
    t=int.from_bytes(data[base+4*op:base+4*op+4],'little')
    to=va2off(t); name=None
    if to is not None and data[to]==0xB8 and data[to+5]==0xC3:
        name=cstr(int.from_bytes(data[to+1:to+5],'little'))
    if name and not re.match(r'^(C|S)?MSG_[A-Z0-9_]+$', name): name=None
    rows.append((op,name))

named=[(o,n) for o,n in rows if n]
print("named opcodes: %d   unnamed/'unknown': %d   total slots: %d"%(len(named),len(rows)-len(named),len(rows)))
mapping={n:o for o,n in named}
json.dump(dict(sorted(mapping.items(), key=lambda kv: kv[1])), open(OUT+"/ascension-opcodes.json","w"), indent=1)
with open(OUT+"/ascension-opcodes.csv","w",newline="") as f:
    w=csv.writer(f); w.writerow(["opcode_dec","opcode_hex","name"])
    for o,n in rows: w.writerow([o,"0x%03X"%o,n or ""])
print("wrote ascension-opcodes.json / .csv to",OUT)
