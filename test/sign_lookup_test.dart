import 'package:flutter_test/flutter_test.dart';
import 'package:signlang/services/sign_lookup.dart';

void main() {
  String describe(String text) => SignLookup.translate(text)
      .map((w) => '${w.text}:${w.kind.name}[${w.steps.map((s) => s.video == null ? '-${s.label}' : s.label).join(',')}]')
      .join(' ');

  test('whole phrases win over single words', () {
    expect(describe('Thank you!'), 'thank you:phrase[thank you]');
    expect(describe('Salom, rahmat'), 'salom:phrase[salom] rahmat:phrase[rahmat]');
    expect(describe('Спасибо пожалуйста'), 'спасибо:phrase[спасибо] пожалуйста:phrase[пожалуйста]');
  });

  test('uzbek apostrophes in any form', () {
    expect(describe('yo‘q'), "yo'q:phrase[yo'q]");
    expect(describe('YOʻQ'), "yo'q:phrase[yo'q]");
  });

  test('numbers are composed', () {
    expect(describe('345'), '345:number[300,40,5]');
    expect(describe('17'), '17:number[17]');
    expect(describe('2024'), '2024:number[2000,20,4]');
  });

  test('unknown words are fingerspelled with digraphs', () {
    expect(describe('Shoxo‘ng'), "shoxo'ng:letter[Sh,O,X,O',Ng]");
    expect(describe('papa'), 'papa:letter[-P,A,-P,A]');
    expect(describe('мама'), 'мама:missing[-мама]');
  });
}
