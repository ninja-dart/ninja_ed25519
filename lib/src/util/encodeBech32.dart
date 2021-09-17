import 'package:bech32/bech32.dart';
import 'package:ninja_basex/ninja_basex.dart';

String encodeBech32(String hrp, List<int> data,
    {int? padding, int maxBechLength = Bech32Validations.maxInputLength}) {
  final bytes = toBaseBytes(data, 32, padding: padding);
  final bech = Bech32(hrp, bytes);
  return bech32.encode(bech, maxBechLength);
}

List<int> decodeBech32(String input,
    {int maxBechLength = Bech32Validations.maxInputLength}) {
  final bech = bech32.decode(input, maxBechLength);
  var data = fromBaseBytes(bech.data, 32);
  return data;
}
