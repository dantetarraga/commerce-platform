"""Lleva las animaciones Lottie de los estados vacíos a la paleta de Apamuy.

Uso (desde mobile/): python tool/brand/recolor_empty_lotties.py
Lee los originales de tool/brand/lottie_src/ y escribe assets/animations/empty/.
Cada archivo tiene su propio mapa para respetar el orden claro→oscuro del dibujo.
"""
import json
import pathlib

TERRACOTA = 'B84A2B'
TERRACOTA_700 = '8F3920'
TERRACOTA_300 = 'F09A7B'
TERRACOTA_50 = 'F7E6DC'
HIERBA = '4E7A40'
PAPEL = 'FBF7F2'
TINTA = '2A1A14'
PIEDRA = '6E5F56'
ARENA = 'C9B8A8'
GRIS_ALTO = 'EADFD3'

MAPS = {
    'cut': {'fb743d': TERRACOTA, 'e3361f': TERRACOTA_700, 'ffc039': TERRACOTA_300, 'f9ebd0': TERRACOTA_50},
    'emptyBag': {
        '313ed3': TERRACOTA_700, '4e6aff': TERRACOTA, '8fa1ff': TERRACOTA_300, 'e7eeff': TERRACOTA_50,
        '00c89f': HIERBA, 'ffa000': TERRACOTA_300, 'ff4d69': HIERBA,
    },
    'door': {
        'ff4d69': TERRACOTA, '4e6aff': PIEDRA, '8fa1ff': ARENA, 'a4bbec': GRIS_ALTO, 'e7eeff': TERRACOTA_50,
        '00c89f': HIERBA, 'ffa000': TERRACOTA_300,
    },
    'knot': {'1138f7': HIERBA},
    'tangle': {'ff3838': TERRACOTA},
    'search': {
        '3a5792': TERRACOTA_700, '4b6cb5': TERRACOTA, '5e86c9': TERRACOTA, '789fd3': TERRACOTA_300,
        'e1e7f6': TERRACOTA_50, 'f1f1f1': PAPEL, 'd23e34': TINTA,
    },
    'receipt': {
        '05bba9': TERRACOTA, 'b0ebd7': TERRACOTA_50, 'ffde54': HIERBA, '2c4053': PAPEL, '37373c': TINTA,
    },
}


def to_hex(c):
    return ''.join(f'{round(max(0, min(1, x)) * 255):02x}' for x in c[:3])


def to_rgb(h):
    return [int(h[i:i + 2], 16) / 255 for i in (0, 2, 4)]


def match(color, mapping):
    """Color de destino si el original coincide (con tolerancia de redondeo)."""
    rgb = [round(x * 255) for x in color[:3]]
    for source, target in mapping.items():
        if all(abs(a - b) <= 2 for a, b in zip(rgb, (int(source[i:i + 2], 16) for i in (0, 2, 4)))):
            return target
    return None


def recolor(node, mapping, missing):
    if isinstance(node, dict):
        if node.get('ty') in ('fl', 'st') and 'c' in node:
            prop = node['c']
            values = [prop['k']] if not prop.get('a') else [kf['s'] for kf in prop['k'] if 's' in kf]
            for v in values:
                target = match(v, mapping)
                if target is not None:
                    v[:3] = to_rgb(target)
                elif to_hex(v) != 'ffffff':
                    missing.add(to_hex(v))
        for child in node.values():
            recolor(child, mapping, missing)
    elif isinstance(node, list):
        for child in node:
            recolor(child, mapping, missing)


def main():
    root = pathlib.Path(__file__).resolve().parents[2]
    src = root / 'tool/brand/lottie_src'
    out = root / 'assets/animations/empty'
    for name, mapping in MAPS.items():
        data = json.loads((src / f'{name}.json').read_text(encoding='utf-8'))
        missing = set()
        recolor(data, {k.lower(): v for k, v in mapping.items()}, missing)
        if missing:
            raise SystemExit(f'{name}: colores sin mapear {sorted(missing)}')
        (out / f'{name}.json').write_text(json.dumps(data, separators=(',', ':')), encoding='utf-8')
        print(f'{name}: ok')


if __name__ == '__main__':
    main()
