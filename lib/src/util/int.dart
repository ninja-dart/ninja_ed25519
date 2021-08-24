int load3(Iterable<int> input) {
  final values = input.iterator;
  int r;
  r = values.next;
  r |= values.next << 8;
  r |= values.next << 16;
  return r;
}

int load4(Iterable<int> input) {
  final values = input.iterator;
  int r;
  r = values.next;
  r |= values.next << 8;
  r |= values.next << 16;
  r |= values.next << 24;
  return r;
}

extension MoveNext on Iterator<int> {
  int get next {
    moveNext();
    return current;
  }
}