"""Lleva las animaciones Lottie de LottieFiles a la paleta de Apamuy.

Uso (desde mobile/): python tool/brand/recolor_lotties.py
Lee los originales de tool/brand/lottie_src/ y escribe assets/animations/
(la moto de las esperas largas y del arranque).
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



# La moto de AppWaitLoader: piel y faro quedan; la caja es el pedido (hierba).
LOADERS = {
    'moto': {
        'f25d27': TERRACOTA, 'ed121d': TERRACOTA_700, 'ca8108': TERRACOTA_300, 'ffffb5': TERRACOTA_50,
        '000000': TINTA, '333333': TINTA, '062a46': TINTA, '4d4d4d': PIEDRA, '989898': PIEDRA,
        'b2b2b2': ARENA, 'cbcbcb': ARENA, 'e5e5e5': GRIS_ALTO, 'f1f1f1': PAPEL,
        '3e5778': HIERBA, 'ffd2aa': 'FFD2AA',
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
    targets = [(name, mapping, root / 'assets/animations') for name, mapping in LOADERS.items()]
    for name, mapping, out in targets:
        data = json.loads((src / f'{name}.json').read_text(encoding='utf-8'))
        missing = set()
        recolor(data, {k.lower(): v for k, v in mapping.items()}, missing)
        if missing:
            raise SystemExit(f'{name}: colores sin mapear {sorted(missing)}')
        (out / f'{name}.json').write_text(json.dumps(data, separators=(',', ':')), encoding='utf-8')
        print(f'{name}: ok')


if __name__ == '__main__':
    main()
