import 'yooz/yooz.dart';


void main() {
  var yooz = new YouzParser();

  String inputCode = '''
(
+ دارت چیه؟
- دارت یه زبان فوق العاده است  ـ  دارت مال گوگله
)
''';


  const Message = "دارت چیه؟";

  yooz.parse(inputCode);

  final response = yooz.getResponse(Message);
  print(response);
}
