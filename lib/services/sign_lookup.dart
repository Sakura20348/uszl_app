/// Turns text into a sequence of sign videos from the app's assets:
///   1. whole words / phrases that have their own sign (assets/videos/feelings_fixed),
///   2. numbers (assets/videos/numbers_fixed, composed like 345 → 300 + 40 + 5),
///   3. anything else is fingerspelled with the alphabet (assets/videos/alphabet_fixed).
library;

enum SignKind { phrase, number, letter, missing }

class SignStep {
  final String label;    // what this step shows, e.g. "rahmat", "300", "Sh"
  final String? video;   // asset path, null when there is no sign for it
  final SignKind kind;
  final int word;        // index of the typed word/phrase this step belongs to
  const SignStep(this.label, this.video, this.kind, this.word);
}

/// One typed word or phrase and the steps that show it.
class SignWord {
  final String text;
  final SignKind kind;   // phrase / number / letter (= fingerspelled) / missing
  final List<SignStep> steps;
  final int tokens;      // how many typed words this covers ("thank you" = 2)
  const SignWord(this.text, this.kind, this.steps, {this.tokens = 1});
}

class SignLookup {
  SignLookup._();

  static const String _phrases = 'assets/videos/feelings_fixed/';
  static const String _letters = 'assets/videos/alphabet_fixed/';
  static const String _numbers = 'assets/videos/numbers_fixed/';

  /// video name → how people write it (uz / ru / en, lowercase, "'" for o‘ g‘ and ʼ).
  static const Map<String, List<String>> _phraseWords = {
    'acquaintance': ['tanish', 'знакомый', 'acquaintance'],
    'always': ['doim', 'har doim', 'всегда', 'always'],
    'assalomu_alaykum': ['assalomu alaykum', 'ассалому алейкум', 'ассаламу алейкум'],
    'by_chance': ['tasodifan', 'случайно', 'by chance'],
    'bye': ['xayr', 'пока', 'до свидания', 'bye', 'goodbye'],
    'didnt_recognize': ['tanimadim', 'не узнал', "didn't recognize"],
    'every': ['har bir', 'каждый', 'every'],
    'everyone': ['hamma', 'все', 'everyone', 'everybody'],
    'from_where': ['qayerdan', 'откуда', 'from where'],
    'gestural_name': ['imo-ishora ism', 'жестовое имя', 'sign name'],
    'hello': ['salom', 'привет', 'здравствуйте', 'hello', 'hi'],
    'he_or_she': ['u', 'он', 'она', 'he', 'she'],
    'how': ['qanday', 'как', 'how'],
    'how_much': ['qancha', 'necha', 'сколько', 'how much', 'how many'],
    'I_am': ['men', 'я', 'i am', "i'm", 'i'],
    'i_have': ['menda bor', 'у меня есть', 'i have'],
    'it_hase_been': ["bo'lgan", 'было', 'it has been'],
    'it_will_happen': ["bo'ladi", 'будет', 'it will happen', 'will be'],
    'low': ['past', 'низкий', 'low'],
    'many': ["ko'p", 'много', 'many', 'a lot'],
    'more': ["ko'proq", 'больше', 'more'],
    'my': ['mening', 'мой', 'моя', 'моё', 'my'],
    'my_own': ["o'zimniki", 'мой собственный', 'my own'],
    'myself': ["o'zim", 'сам', 'myself'],
    'name': ['ism', 'ismim', 'имя', 'name'],
    'never': ['hech qachon', 'никогда', 'never'],
    'nobody': ['hech kim', 'никто', 'nobody'],
    'no': ["yo'q", 'нет', 'no'],
    'no_need': ['kerak emas', 'не нужно', 'no need'],
    'nothing': ['hech narsa', 'ничего', 'nothing'],
    'own': ["o'z", 'свой', 'own'],
    'patronymic': ['otasining ismi', 'отчество', 'patronymic'],
    'please': ['iltimos', 'пожалуйста', 'please'],
    'precise': ['aniq', 'точно', 'exactly', 'precise'],
    'slowly': ['sekin', 'медленно', 'slowly'],
    'sometimes': ["ba'zan", 'иногда', 'sometimes'],
    'surname': ['familiya', 'фамилия', 'surname'],
    'thank_you': ['rahmat', 'спасибо', 'thank you', 'thanks'],
    'that_was': ['u edi', 'это было', 'that was'],
    'there_is': ['bor', 'есть', 'there is'],
    'they': ['ular', 'они', 'they'],
    'this': ['bu', 'это', 'this'],
    'to_apologize': ['kechirasiz', 'kechirim', 'извините', 'простите', 'sorry', 'excuse me'],
    'to_get_acquainted': ['tanishaylik', 'tanishmoq', 'познакомиться', 'nice to meet you'],
    'to_go': ['bormoq', 'boraman', 'идти', 'go'],
    'to_invite': ['taklif qilmoq', 'пригласить', 'invite'],
    'to_sorry': ['afsus', 'жаль', 'pity'],
    'to_wait': ['kuting', 'kutmoq', 'подождите', 'ждать', 'wait'],
    'we': ['biz', 'мы', 'we'],
    'what': ['nima', 'что', 'what'],
    'when': ['qachon', 'когда', 'when'],
    'where': ['qayerda', 'где', 'where'],
    'where_to': ['qayerga', 'куда', 'where to'],
    'who': ['kim', 'кто', 'who'],
    'whose': ['kimning', 'чей', 'whose'],
    'why': ['nega', 'nima uchun', 'почему', 'зачем', 'why'],
    'yes': ['ha', 'да', 'yes'],
    'you': ['sen', 'ты', 'you'],
    'You': ['siz', 'вы'],
    'your': ['sening', 'sizning', 'твой', 'ваш', 'your'],
    'yourself': ["o'zing", 'себя', 'yourself'],
    'you_have': ['senda bor', 'у тебя есть', 'you have'],
  };

  /// Uzbek Latin letters that have an alphabet video (P and Y have none yet).
  static const Map<String, String> _letterVideos = {
    'a': 'level_A', 'b': 'level_B', 'ch': 'level_Ch', 'd': 'level_D', 'e': 'level_E', 'f': 'level_F',
    'g': 'level_G', "g'": 'level_G_apos', 'h': 'level_H', 'i': 'level_I', 'j': 'level_J', 'k': 'level_K',
    'l': 'level_L', 'm': 'level_M', 'n': 'level_N', 'ng': 'level_Ng', 'o': 'Level_O', "o'": 'level_O_apos',
    'q': 'level_Q', 'r': 'level_R', 's': 'level_S', 'sh': 'level_Sh', 't': 'level_T', 'u': 'level_U',
    'v': 'level_V', 'x': 'level_X', 'z': 'level_Z',
  };

  static const Set<int> _numberVideos = {
    0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 30, 40, 50, 60, 70, 80, 90,
    100, 200, 300, 400, 500, 600, 700, 800, 900, 1000, 2000, 3000, 4000, 5000, 1000000,
  };

  static final Map<String, String> _phraseIndex = {
    for (final e in _phraseWords.entries) for (final w in e.value) w: e.key,
  };
  static final int _longestPhrase = _phraseIndex.keys.map((k) => k.split(' ').length).reduce((a, b) => a > b ? a : b);

  /// Lowercase, one kind of apostrophe, no punctuation: how words are matched.
  static String normalize(String text) => text
      .toLowerCase()
      .replaceAll(RegExp("[‘’ʻʼ`´]"), "'")
      .replaceAll(RegExp(r"[^\p{L}\p{N}' -]", unicode: true), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  static List<SignWord> translate(String text) {
    final tokens = normalize(text).split(' ').where((t) => t.isNotEmpty).toList();
    final words = <SignWord>[];
    int i = 0;
    while (i < tokens.length) {
      // longest phrase first ("thank you" before "thank")
      String? video; int used = 0;
      for (int n = _longestPhrase.clamp(1, tokens.length - i); n >= 1 && video == null; n--) {
        final candidate = tokens.sublist(i, i + n).join(' ');
        if (_phraseIndex.containsKey(candidate)) { video = _phraseIndex[candidate]; used = n; }
      }
      final index = words.length;
      if (video != null) {
        final label = tokens.sublist(i, i + used).join(' ');
        words.add(SignWord(label, SignKind.phrase, [SignStep(label, '$_phrases$video.mp4', SignKind.phrase, index)], tokens: used));
        i += used;
        continue;
      }
      final token = tokens[i];
      final number = int.tryParse(token);
      if (number != null) {
        words.add(SignWord(token, SignKind.number, [for (final part in _numberParts(number)) SignStep('$part', '$_numbers$part.mp4', SignKind.number, index)]));
      } else {
        final letters = _spell(token, index);
        final bool any = letters.any((s) => s.video != null);
        words.add(SignWord(token, any ? SignKind.letter : SignKind.missing, any ? letters : [SignStep(token, null, SignKind.missing, index)]));
      }
      i++;
    }
    return words;
  }

  /// 345 → [300, 40, 5]; 2024 → [2000, 20, 4]; numbers without a way to compose them are read digit by digit.
  static List<int> _numberParts(int n) {
    if (_numberVideos.contains(n)) return [n];
    if (n < 0 || n >= 6000) return [for (final d in n.abs().toString().split('')) int.parse(d)];
    final parts = <int>[];
    if (n >= 1000) { parts.add(n ~/ 1000 * 1000); n %= 1000; }
    if (n >= 100) { parts.add(n ~/ 100 * 100); n %= 100; }
    if (n >= 20) { parts.add(n ~/ 10 * 10); n %= 10; if (n > 0) parts.add(n); }
    else if (n > 0) { parts.add(n); }
    return parts;
  }

  /// Fingerspelling: digraphs (sh, ch, ng, o', g') first, then single letters.
  static List<SignStep> _spell(String word, int index) {
    final steps = <SignStep>[];
    int i = 0;
    while (i < word.length) {
      final two = i + 1 < word.length ? word.substring(i, i + 2) : '';
      if (two.isNotEmpty && _letterVideos.containsKey(two)) {
        steps.add(SignStep(_display(two), '$_letters${_letterVideos[two]}.mp4', SignKind.letter, index));
        i += 2;
      } else {
        final one = word[i];
        if (one != "'" && one != '-') {
          final video = _letterVideos[one];
          steps.add(SignStep(_display(one), video == null ? null : '$_letters$video.mp4', video == null ? SignKind.missing : SignKind.letter, index));
        }
        i++;
      }
    }
    return steps;
  }

  static String _display(String letter) => letter.length == 1 ? letter.toUpperCase() : letter[0].toUpperCase() + letter.substring(1);
}
