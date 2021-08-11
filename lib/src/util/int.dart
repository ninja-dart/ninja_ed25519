import 'dart:typed_data';

int load3(Uint8List input) {
  int r;
  r = input[0];
  r |= input[1] << 8;
  r |= input[2] << 16;
  return r;
}

int load4(Uint8List input) {
  int r;
  r = input[0];
  r |= input[1] << 8;
  r |= input[2] << 16;
  r |= input[3] << 24;
  return r;
}
