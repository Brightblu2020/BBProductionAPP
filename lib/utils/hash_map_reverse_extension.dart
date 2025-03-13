extension ReverseMyMap on Map {
  Map<String, dynamic> justReverse() {
    final newmap = <String, dynamic>{};
    for (String _key in keys.toList().reversed) {
      newmap[_key] = this[_key];
    }
    return newmap;
  }
}
