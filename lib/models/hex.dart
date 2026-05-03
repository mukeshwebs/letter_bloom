import 'dart:math';

/// Axial hex coordinate (pointy-top).
class Hex {
  final int q;
  final int r;
  const Hex(this.q, this.r);

  @override
  bool operator ==(Object other) => other is Hex && other.q == q && other.r == r;
  @override
  int get hashCode => Object.hash(q, r);

  @override
  String toString() => 'Hex($q,$r)';

  static const List<Hex> _dirs = [
    Hex(1, 0), Hex(1, -1), Hex(0, -1),
    Hex(-1, 0), Hex(-1, 1), Hex(0, 1),
  ];

  Hex neighbor(int dir) => Hex(q + _dirs[dir].q, r + _dirs[dir].r);

  Iterable<Hex> get neighbors => _dirs.map((d) => Hex(q + d.q, r + d.r));

  /// Hexagonal region of given radius around origin.
  static List<Hex> hexagon(int radius) {
    final out = <Hex>[];
    for (int q = -radius; q <= radius; q++) {
      final r1 = max(-radius, -q - radius);
      final r2 = min(radius, -q + radius);
      for (int r = r1; r <= r2; r++) {
        out.add(Hex(q, r));
      }
    }
    return out;
  }

  /// Pixel center for a pointy-top hex of given size (circumradius).
  Point<double> toPixel(double size) {
    final x = size * (sqrt(3) * q + sqrt(3) / 2 * r);
    final y = size * (3 / 2 * r);
    return Point(x, y);
  }
}
