"""Outfit/pattern art from the Pocket Purr Christmas design (200x200 viewBox), with anchors."""
import re

def parse(d):
    """SVG path -> list of absolute ops: ('M',x,y) ('L',x,y) ('Q',cx,cy,x,y) ('C',c1x,c1y,c2x,c2y,x,y) ('Z',)"""
    toks = re.findall(r'[MLHVCSQTZmlhvcsqtz]|-?\d*\.?\d+(?:e-?\d+)?', d)
    i = 0; ops = []; cx = cy = sx = sy = 0; cmd = None; lastq = None; lastc = None
    def num():
        nonlocal i; v = float(toks[i]); i += 1; return v
    while i < len(toks):
        if re.match(r'[A-Za-z]', toks[i]): cmd = toks[i]; i += 1
        rel = cmd.islower(); C = cmd.upper()
        ox, oy = (cx, cy) if rel else (0, 0)
        if C == 'Z':
            ops.append(('Z',)); cx, cy = sx, sy; lastq = lastc = None; continue
        if C == 'M':
            x, y = num()+ox, num()+oy; ops.append(('M', x, y)); cx, cy, sx, sy = x, y, x, y
            cmd = 'l' if rel else 'L'; lastq = lastc = None
        elif C == 'L':
            x, y = num()+ox, num()+oy; ops.append(('L', x, y)); cx, cy = x, y; lastq = lastc = None
        elif C == 'H':
            x = num()+ox; ops.append(('L', x, cy)); cx = x; lastq = lastc = None
        elif C == 'V':
            y = num()+oy; ops.append(('L', cx, y)); cy = y; lastq = lastc = None
        elif C == 'Q':
            qx, qy, x, y = num()+ox, num()+oy, num()+ox, num()+oy
            ops.append(('Q', qx, qy, x, y)); lastq = (qx, qy); cx, cy = x, y; lastc = None
        elif C == 'T':
            qx, qy = (2*cx - lastq[0], 2*cy - lastq[1]) if lastq else (cx, cy)
            x, y = num()+ox, num()+oy
            ops.append(('Q', qx, qy, x, y)); lastq = (qx, qy); cx, cy = x, y; lastc = None
        elif C == 'C':
            a, b, c, e, x, y = num()+ox, num()+oy, num()+ox, num()+oy, num()+ox, num()+oy
            ops.append(('C', a, b, c, e, x, y)); lastc = (c, e); cx, cy = x, y; lastq = None
        elif C == 'S':
            a, b = (2*cx - lastc[0], 2*cy - lastc[1]) if lastc else (cx, cy)
            c, e, x, y = num()+ox, num()+oy, num()+ox, num()+oy
            ops.append(('C', a, b, c, e, x, y)); lastc = (c, e); cx, cy = x, y; lastq = None
    return ops

def P(anchor, d, fill=None, stroke=None, w=0, dash=None, op=1.0, clip=None, cap='round'):
    return dict(kind='path', anchor=anchor, ops=parse(d), fill=fill, stroke=stroke, w=w, dash=dash, op=op, clip=clip, cap=cap)
def E(anchor, cx, cy, rx, ry=None, fill=None, stroke=None, w=0, op=1.0, clip=None):
    return dict(kind='ellipse', anchor=anchor, c=(cx, cy), r=(rx, ry if ry is not None else rx), fill=fill, stroke=stroke, w=w, op=op, clip=clip, dash=None, cap='round')

# anchors: head (head bbox 40..160 x 36..122), body (52..148 x 113..186), pawL (87,183), pawR (113,183)
# layers: 'body' = after body, before paws/head; 'paw' = after paws; 'head' = after head features; 'top' = last
OUTFITS = {
 'gingerbread': [
   ('body', E('body', 100, 138, 4.5, fill=0xE0413A)), ('body', E('body', 100, 151, 4.5, fill=0xE0413A)),
   ('body', E('body', 98.6, 136.6, 1.4, fill=0xFFB3AE)), ('body', E('body', 98.6, 149.6, 1.4, fill=0xFFB3AE)),
   ('paw', P('pawL', 'M79 180 q2 -2.5 4 0 t4 0 t4 0', stroke=0xFFFFFF, w=2)),
   ('paw', P('pawR', 'M105 180 q2 -2.5 4 0 t4 0 t4 0', stroke=0xFFFFFF, w=2)),
   ('face', P('head', 'M50 104 q2.5 -3 5 0 t5 0 t5 0', stroke=0xFFFFFF, w=2.2)),
   ('face', P('head', 'M135 104 q2.5 -3 5 0 t5 0 t5 0', stroke=0xFFFFFF, w=2.2)),
   ('neck', P('head', 'M100 121 L87 114 L87 128 Z', fill=0xFFFFFF, stroke=0xD9C9B5, w=2)),
   ('neck', P('head', 'M100 121 L113 114 L113 128 Z', fill=0xFFFFFF, stroke=0xD9C9B5, w=2)),
   ('neck', E('head', 100, 121, 4, fill=0xFFFFFF, stroke=0xD9C9B5, w=2)),
 ],
 'reindeer': [
   ('neck', P('head', 'M72 116 Q100 132 128 116', stroke=0xC8323C, w=6)),
   ('neck', E('head', 100, 128, 6, fill=0xE9B949, stroke=0xB8902A, w=2)),
   ('neck', P('head', 'M97.5 130 L102.5 130', stroke=0x8A6A1E, w=1.5)),
   ('top', P('head', 'M80 42 Q100 30 120 42', stroke=0x8A5A3B, w=4)),
   ('top', P('head', 'M88 37 L84 14 M85 23 L76 17 M86 30 L94 22', stroke=0xB9875A, w=6)),
   ('top', P('head', 'M112 37 L116 14 M115 23 L124 17 M114 30 L106 22', stroke=0xB9875A, w=6)),
 ],
 'elf': [
   ('bodypat', P('body', 'M50 146 Q62 122 84 128 Q82 156 56 168 Z', fill=0xE8964A, clip='body')),
   ('bodypat', P('body', 'M122 168 Q138 152 150 144 Q152 172 134 186 Z', fill=0x3A3438, clip='body')),
   ('headpat', P('head', 'M36 60 Q58 32 88 42 Q84 70 42 82 Z', fill=0xE8964A, clip='head')),
   ('headpat', P('head', 'M114 40 Q150 38 164 70 Q140 80 116 62 Z', fill=0x3A3438, clip='head')),
   ('neck', P('head', 'M112 124 L120 152 L130 148 L122 122 Z', fill=0xD9433F, stroke=0xB0302D, w=1.5)),
   ('neck', P('head', 'M116 138 L126 135', stroke=0xFFFFFF, w=3)),
   ('neck', P('head', 'M70 116 Q100 134 130 116', stroke=0xD9433F, w=9)),
   ('neck', P('head', 'M82 121 L83 129 M100 124 L100 132 M118 121 L117 129', stroke=0xFFFFFF, w=3)),
   ('top', P('head', 'M80 40 Q100 30 122 38 L112 2 Z', fill=0x3E8E4F, stroke=0x2A5E37, w=2.5)),
   ('top', P('head', 'M78 42 Q100 32 124 40', stroke=0xFFFFFF, w=7)),
   ('top', E('head', 112, 3, 5, fill=0xE9B949, stroke=0xB8902A, w=2)),
 ],
 'frost': [
   ('face', P('head', 'M46 72 Q56 46 98 39', stroke=0xFFFFFF, w=3.5, op=0.8)),
   ('neck', P('head', 'M80 124 L74 152 L86 154 L90 126 Z', fill=0x8FD9C0, stroke=0x5FAE95, w=1.5)),
   ('neck', P('head', 'M76 146 L86 148', stroke=0x5FAE95, w=2)),
   ('neck', P('head', 'M70 116 Q100 134 130 116', stroke=0x8FD9C0, w=10)),
   ('neck', P('head', 'M70 116 Q100 134 130 116', stroke=0x5FAE95, w=2, dash=(3, 4), cap='butt')),
   ('paw', E('pawL', 87, 182, 14, 9, fill=0xFFFFFF, stroke=0xC9D2E2, w=2.5)),
   ('paw', E('pawR', 113, 182, 14, 9, fill=0xFFFFFF, stroke=0xC9D2E2, w=2.5)),
   ('paw', P('pawL', 'M74 177 Q87 170 100 177', stroke=0x8FD9C0, w=4.5)),
   ('paw', P('pawR', 'M100 177 Q113 170 126 177', stroke=0x8FD9C0, w=4.5)),
 ],
 'cocoa': [
   ('body', P('body', 'M54 150 C56 130 64 118 74 113 L126 113 C136 118 144 130 146 150 C148 166 147 176 142 178 L58 178 C53 176 52 166 54 150 Z', fill=0xC8323C, stroke=0x8E1F29, w=2.5, clip='body')),
   ('body', P('body', 'M56 152 L64 146 L72 152 L80 146 L88 152 L96 146 L104 152 L112 146 L120 152 L128 146 L136 152 L144 147', stroke=0xF3E3C8, w=4, clip='body')),
   ('body', E('body', 76, 166, 2.4, fill=0xF3E3C8)), ('body', E('body', 100, 168, 2.4, fill=0xF3E3C8)), ('body', E('body', 124, 166, 2.4, fill=0xF3E3C8)),
   ('neck', P('head', 'M74 114 Q100 128 126 114', stroke=0xF3E3C8, w=6)),
 ],
 'midnight': [
   ('neck', P('head', 'M72 116 Q100 132 128 116', stroke=0xE9B949, w=5)),
   ('neck', E('head', 100, 128, 6, fill=0xFFD166, stroke=0xC99A2E, w=2)),
   ('neck', P('head', 'M97.5 130 L102.5 130', stroke=0x8A6A1E, w=1.5)),
   ('top', P('head', 'M84 40 Q100 33 116 40', stroke=0xE9B949, w=4)),
   ('top', P('head', 'M100 15 L102.7 22.3 L110.5 22.6 L104.4 27.4 L106.5 34.9 L100 30.6 L93.5 34.9 L95.6 27.4 L89.5 22.6 L97.3 22.3 Z', fill=0xFFD166, stroke=0xE0A82E, w=1.5)),
 ],
}
