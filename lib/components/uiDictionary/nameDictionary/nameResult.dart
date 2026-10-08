import 'package:flutter/cupertino.dart';
import 'package:signlang/l10n/app_localizations.dart';

// =======================================================================
// Last Seen
// =======================================================================
class QuestionCardsData {
  final BuildContext context; QuestionCardsData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> questionCardsItems = [
    { 'id': '0', 'word': loc.translate('meaning'), 'wordSub': loc.translate('meaning_sub'), 'image': 'web/icons/book_icon.png' },
    { 'id': '1', 'word': loc.translate('hand_shape'), 'wordSub': loc.translate('hand_shape_sub'), 'image': 'web/icons/hand.png' },
    { 'id': '2', 'word': loc.translate('action'), 'wordSub': loc.translate('action_sub'), 'image': 'web/icons/hand_move.png' },
  ];
}

class QuestionCardsGrandpaData {
  final BuildContext context; QuestionCardsGrandpaData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> grandpaItems = [
    { 'id': '0', 'word': loc.translate('meaning'), 'wordSub': loc.translate('meaning_grandfather'), 'image': 'web/icons/book_icon.png' },
    { 'id': '1', 'word': loc.translate('hand_shape'), 'wordSub': loc.translate('hand_shape_sub'), 'image': 'web/icons/hand.png' },
    { 'id': '2', 'word': loc.translate('action'), 'wordSub': loc.translate('action_sub'), 'image': 'web/icons/hand_move.png' },
  ];
}

class QuestionCardsGrandmotherData {
  final BuildContext context; QuestionCardsGrandmotherData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> grandmotherItems = [
    { 'id': '0', 'word': loc.translate('meaning'), 'wordSub': loc.translate('meaning_grandmother'), 'image': 'web/icons/book_icon.png' },
    { 'id': '1', 'word': loc.translate('hand_shape'), 'wordSub': loc.translate('hand_shape_sub'), 'image': 'web/icons/hand.png' },
    { 'id': '2', 'word': loc.translate('action'), 'wordSub': loc.translate('action_sub'), 'image': 'web/icons/hand_move.png' },
  ];
}

class QuestionCardsFatherData {
  final BuildContext context; QuestionCardsFatherData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> fatherItems = [
    { 'id': '0', 'word': loc.translate('meaning'), 'wordSub': loc.translate('meaning_father'), 'image': 'web/icons/book_icon.png' },
    { 'id': '1', 'word': loc.translate('hand_shape'), 'wordSub': loc.translate('hand_shape_sub'), 'image': 'web/icons/hand.png' },
    { 'id': '2', 'word': loc.translate('action'), 'wordSub': loc.translate('action_sub'), 'image': 'web/icons/hand_move.png' },
  ];
}

class QuestionCardsMotherData {
  final BuildContext context; QuestionCardsMotherData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> motherItems = [
    { 'id': '0', 'word': loc.translate('meaning'), 'wordSub': loc.translate('meaning_mother'), 'image': 'web/icons/book_icon.png' },
    { 'id': '1', 'word': loc.translate('hand_shape'), 'wordSub': loc.translate('hand_shape_sub'), 'image': 'web/icons/hand.png' },
    { 'id': '2', 'word': loc.translate('action'), 'wordSub': loc.translate('action_sub'), 'image': 'web/icons/hand_move.png' },
  ];
}

class QuestionCardsSisterData {
  final BuildContext context; QuestionCardsSisterData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> sisterItems = [
    { 'id': '0', 'word': loc.translate('meaning'), 'wordSub': loc.translate('meaning_sister'), 'image': 'web/icons/book_icon.png' },
    { 'id': '1', 'word': loc.translate('hand_shape'), 'wordSub': loc.translate('hand_shape_sub'), 'image': 'web/icons/hand.png' },
    { 'id': '2', 'word': loc.translate('action'), 'wordSub': loc.translate('action_sub'), 'image': 'web/icons/hand_move.png' },
  ];
}

class QuestionCardsBrotherData {
  final BuildContext context; QuestionCardsBrotherData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> brotherItems = [
    { 'id': '0', 'word': loc.translate('meaning'), 'wordSub': loc.translate('meaning_brother'), 'image': 'web/icons/book_icon.png' },
    { 'id': '1', 'word': loc.translate('hand_shape'), 'wordSub': loc.translate('hand_shape_sub'), 'image': 'web/icons/hand.png' },
    { 'id': '2', 'word': loc.translate('action'), 'wordSub': loc.translate('action_sub'), 'image': 'web/icons/hand_move.png' },
  ];
}

class QuestionCardsBabyData {
  final BuildContext context; QuestionCardsBabyData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> babyItems = [
    { 'id': '0', 'word': loc.translate('meaning'), 'wordSub': loc.translate('meaning_baby'), 'image': 'web/icons/book_icon.png' },
    { 'id': '1', 'word': loc.translate('hand_shape'), 'wordSub': loc.translate('hand_shape_sub'), 'image': 'web/icons/hand.png' },
    { 'id': '2', 'word': loc.translate('action'), 'wordSub': loc.translate('action_sub'), 'image': 'web/icons/hand_move.png' },
  ];
}

class QuestionCardsSonData {
  final BuildContext context; QuestionCardsSonData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> sonItems = [
    { 'id': '0', 'word': loc.translate('meaning'), 'wordSub': loc.translate('meaning_son'), 'image': 'web/icons/book_icon.png' },
    { 'id': '1', 'word': loc.translate('hand_shape'), 'wordSub': loc.translate('hand_shape_sub'), 'image': 'web/icons/hand.png' },
    { 'id': '2', 'word': loc.translate('action'), 'wordSub': loc.translate('action_sub'), 'image': 'web/icons/hand_move.png' },
  ];
}

class QuestionCardsDaughterData {
  final BuildContext context; QuestionCardsDaughterData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> daughterItems = [
    { 'id': '0', 'word': loc.translate('meaning'), 'wordSub': loc.translate('meaning_daughter'), 'image': 'web/icons/book_icon.png' },
    { 'id': '1', 'word': loc.translate('hand_shape'), 'wordSub': loc.translate('hand_shape_sub'), 'image': 'web/icons/hand.png' },
    { 'id': '2', 'word': loc.translate('action'), 'wordSub': loc.translate('action_sub'), 'image': 'web/icons/hand_move.png' },
  ];
}

class QuestionCardsUncleData {
  final BuildContext context; QuestionCardsUncleData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> uncleItems = [
    { 'id': '0', 'word': loc.translate('meaning'), 'wordSub': loc.translate('meaning_uncle'), 'image': 'web/icons/book_icon.png' },
    { 'id': '1', 'word': loc.translate('hand_shape'), 'wordSub': loc.translate('hand_shape_sub'), 'image': 'web/icons/hand.png' },
    { 'id': '2', 'word': loc.translate('action'), 'wordSub': loc.translate('action_sub'), 'image': 'web/icons/hand_move.png' },
  ];
}

class QuestionCardsAuntData {
  final BuildContext context; QuestionCardsAuntData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> auntItems = [
    { 'id': '0', 'word': loc.translate('meaning'), 'wordSub': loc.translate('meaning_aunt'), 'image': 'web/icons/book_icon.png' },
    { 'id': '1', 'word': loc.translate('hand_shape'), 'wordSub': loc.translate('hand_shape_sub'), 'image': 'web/icons/hand.png' },
    { 'id': '2', 'word': loc.translate('action'), 'wordSub': loc.translate('action_sub'), 'image': 'web/icons/hand_move.png' },
  ];
}

class QuestionCardsCousinData {
  final BuildContext context; QuestionCardsCousinData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> cousinItems = [
    { 'id': '0', 'word': loc.translate('meaning'), 'wordSub': loc.translate('meaning_cousin'), 'image': 'web/icons/book_icon.png' },
    { 'id': '1', 'word': loc.translate('hand_shape'), 'wordSub': loc.translate('hand_shape_sub'), 'image': 'web/icons/hand.png' },
    { 'id': '2', 'word': loc.translate('action'), 'wordSub': loc.translate('action_sub'), 'image': 'web/icons/hand_move.png' },
  ];
}

class QuestionCardsNieceData {
  final BuildContext context; QuestionCardsNieceData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> nieceItems = [
    { 'id': '0', 'word': loc.translate('meaning'), 'wordSub': loc.translate('meaning_niece'), 'image': 'web/icons/book_icon.png' },
    { 'id': '1', 'word': loc.translate('hand_shape'), 'wordSub': loc.translate('hand_shape_sub'), 'image': 'web/icons/hand.png' },
    { 'id': '2', 'word': loc.translate('action'), 'wordSub': loc.translate('action_sub'), 'image': 'web/icons/hand_move.png' },
  ];
}

class QuestionCardsNephewData {
  final BuildContext context; QuestionCardsNephewData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> nephewItems = [
    { 'id': '0', 'word': loc.translate('meaning'), 'wordSub': loc.translate('meaning_nephew'), 'image': 'web/icons/book_icon.png' },
    { 'id': '1', 'word': loc.translate('hand_shape'), 'wordSub': loc.translate('hand_shape_sub'), 'image': 'web/icons/hand.png' },
    { 'id': '2', 'word': loc.translate('action'), 'wordSub': loc.translate('action_sub'), 'image': 'web/icons/hand_move.png' },
  ];
}

class QuestionCardsParentsData {
  final BuildContext context; QuestionCardsParentsData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> parentsItems = [
    { 'id': '0', 'word': loc.translate('meaning'), 'wordSub': loc.translate('meaning_parents'), 'image': 'web/icons/book_icon.png' },
    { 'id': '1', 'word': loc.translate('hand_shape'), 'wordSub': loc.translate('hand_shape_sub'), 'image': 'web/icons/hand.png' },
    { 'id': '2', 'word': loc.translate('action'), 'wordSub': loc.translate('action_sub'), 'image': 'web/icons/hand_move.png' },
  ];
}

class QuestionCardsSiblingsData {
  final BuildContext context; QuestionCardsSiblingsData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> siblingsItems = [
    { 'id': '0', 'word': loc.translate('meaning'), 'wordSub': loc.translate('meaning_siblings'), 'image': 'web/icons/book_icon.png' },
    { 'id': '1', 'word': loc.translate('hand_shape'), 'wordSub': loc.translate('hand_shape_sub'), 'image': 'web/icons/hand.png' },
    { 'id': '2', 'word': loc.translate('action'), 'wordSub': loc.translate('action_sub'), 'image': 'web/icons/hand_move.png' },
  ];
}

class QuestionCardsChildrenData {
  final BuildContext context; QuestionCardsChildrenData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> childrenItems = [
    { 'id': '0', 'word': loc.translate('meaning'), 'wordSub': loc.translate('meaning_children'), 'image': 'web/icons/book_icon.png' },
    { 'id': '1', 'word': loc.translate('hand_shape'), 'wordSub': loc.translate('hand_shape_sub'), 'image': 'web/icons/hand.png' },
    { 'id': '2', 'word': loc.translate('action'), 'wordSub': loc.translate('action_sub'), 'image': 'web/icons/hand_move.png' },
  ];
}

class QuestionCardsHusbandData {
  final BuildContext context; QuestionCardsHusbandData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> husbandItems = [
    { 'id': '0', 'word': loc.translate('meaning'), 'wordSub': loc.translate('meaning_husband'), 'image': 'web/icons/book_icon.png' },
    { 'id': '1', 'word': loc.translate('hand_shape'), 'wordSub': loc.translate('hand_shape_sub'), 'image': 'web/icons/hand.png' },
    { 'id': '2', 'word': loc.translate('action'), 'wordSub': loc.translate('action_sub'), 'image': 'web/icons/hand_move.png' },
  ];
}

class QuestionCardsWifeData {
  final BuildContext context; QuestionCardsWifeData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> wifeItems = [
    { 'id': '0', 'word': loc.translate('meaning'), 'wordSub': loc.translate('meaning_wife'), 'image': 'web/icons/book_icon.png' },
    { 'id': '1', 'word': loc.translate('hand_shape'), 'wordSub': loc.translate('hand_shape_sub'), 'image': 'web/icons/hand.png' },
    { 'id': '2', 'word': loc.translate('action'), 'wordSub': loc.translate('action_sub'), 'image': 'web/icons/hand_move.png' },
  ];
}

class QuestionCardsPersonData {
  final BuildContext context; QuestionCardsPersonData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> personItems = [
    { 'id': '0', 'word': loc.translate('meaning'), 'wordSub': loc.translate('meaning_person'), 'image': 'web/icons/book_icon.png' },
    { 'id': '1', 'word': loc.translate('hand_shape'), 'wordSub': loc.translate('hand_shape_sub'), 'image': 'web/icons/hand.png' },
    { 'id': '2', 'word': loc.translate('action'), 'wordSub': loc.translate('action_sub'), 'image': 'web/icons/hand_move.png' },
  ];
}

class QuestionCardsManData {
  final BuildContext context; QuestionCardsManData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> manItems = [
    { 'id': '0', 'word': loc.translate('meaning'), 'wordSub': loc.translate('meaning_man'), 'image': 'web/icons/book_icon.png' },
    { 'id': '1', 'word': loc.translate('hand_shape'), 'wordSub': loc.translate('hand_shape_sub'), 'image': 'web/icons/hand.png' },
    { 'id': '2', 'word': loc.translate('action'), 'wordSub': loc.translate('action_sub'), 'image': 'web/icons/hand_move.png' },
  ];
}

class QuestionCardsWomanData {
  final BuildContext context; QuestionCardsWomanData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> womanItems = [
    { 'id': '0', 'word': loc.translate('meaning'), 'wordSub': loc.translate('meaning_woman'), 'image': 'web/icons/book_icon.png' },
    { 'id': '1', 'word': loc.translate('hand_shape'), 'wordSub': loc.translate('hand_shape_sub'), 'image': 'web/icons/hand.png' },
    { 'id': '2', 'word': loc.translate('action'), 'wordSub': loc.translate('action_sub'), 'image': 'web/icons/hand_move.png' },
  ];
}

class QuestionCardsBoyData {
  final BuildContext context; QuestionCardsBoyData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> boyItems = [
    { 'id': '0', 'word': loc.translate('meaning'), 'wordSub': loc.translate('meaning_boy'), 'image': 'web/icons/book_icon.png' },
    { 'id': '1', 'word': loc.translate('hand_shape'), 'wordSub': loc.translate('hand_shape_sub'), 'image': 'web/icons/hand.png' },
    { 'id': '2', 'word': loc.translate('action'), 'wordSub': loc.translate('action_sub'), 'image': 'web/icons/hand_move.png' },
  ];
}

class QuestionCardsGirlData {
  final BuildContext context; QuestionCardsGirlData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> girlItems = [
    { 'id': '0', 'word': loc.translate('meaning'), 'wordSub': loc.translate('meaning_girl'), 'image': 'web/icons/book_icon.png' },
    { 'id': '1', 'word': loc.translate('hand_shape'), 'wordSub': loc.translate('hand_shape_sub'), 'image': 'web/icons/hand.png' },
    { 'id': '2', 'word': loc.translate('action'), 'wordSub': loc.translate('action_sub'), 'image': 'web/icons/hand_move.png' },
  ];
}

class QuestionCardsRelativeData {
  final BuildContext context; QuestionCardsRelativeData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> relativeItems = [
    { 'id': '0', 'word': loc.translate('meaning'), 'wordSub': loc.translate('meaning_relative'), 'image': 'web/icons/book_icon.png' },
    { 'id': '1', 'word': loc.translate('hand_shape'), 'wordSub': loc.translate('hand_shape_sub'), 'image': 'web/icons/hand.png' },
    { 'id': '2', 'word': loc.translate('action'), 'wordSub': loc.translate('action_sub'), 'image': 'web/icons/hand_move.png' },
  ];
}

class QuestionCardsMarriageData {
  final BuildContext context; QuestionCardsMarriageData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> marriageItems = [
    { 'id': '0', 'word': loc.translate('meaning'), 'wordSub': loc.translate('meaning_marriage'), 'image': 'web/icons/book_icon.png' },
    { 'id': '1', 'word': loc.translate('hand_shape'), 'wordSub': loc.translate('hand_shape_sub'), 'image': 'web/icons/hand.png' },
    { 'id': '2', 'word': loc.translate('action'), 'wordSub': loc.translate('action_sub'), 'image': 'web/icons/hand_move.png' },
  ];
}

class QuestionCardsBrideData {
  final BuildContext context; QuestionCardsBrideData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> brideItems = [
    { 'id': '0', 'word': loc.translate('meaning'), 'wordSub': loc.translate('meaning_bride'), 'image': 'web/icons/book_icon.png' },
    { 'id': '1', 'word': loc.translate('hand_shape'), 'wordSub': loc.translate('hand_shape_sub'), 'image': 'web/icons/hand.png' },
    { 'id': '2', 'word': loc.translate('action'), 'wordSub': loc.translate('action_sub'), 'image': 'web/icons/hand_move.png' },
  ];
}

class QuestionCardsSpouseData {
  final BuildContext context; QuestionCardsSpouseData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> spouseItems = [
    { 'id': '0', 'word': loc.translate('meaning'), 'wordSub': loc.translate('meaning_spouse'), 'image': 'web/icons/book_icon.png' },
    { 'id': '1', 'word': loc.translate('hand_shape'), 'wordSub': loc.translate('hand_shape_sub'), 'image': 'web/icons/hand.png' },
    { 'id': '2', 'word': loc.translate('action'), 'wordSub': loc.translate('action_sub'), 'image': 'web/icons/hand_move.png' },
  ];
}

class QuestionCardsTeenagerData {
  final BuildContext context; QuestionCardsTeenagerData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> teenagerItems = [
    { 'id': '0', 'word': loc.translate('meaning'), 'wordSub': loc.translate('meaning_teenager'), 'image': 'web/icons/book_icon.png' },
    { 'id': '1', 'word': loc.translate('hand_shape'), 'wordSub': loc.translate('hand_shape_sub'), 'image': 'web/icons/hand.png' },
    { 'id': '2', 'word': loc.translate('action'), 'wordSub': loc.translate('action_sub'), 'image': 'web/icons/hand_move.png' },
  ];
}

class QuestionCardsCountrywomanData {
  final BuildContext context; QuestionCardsCountrywomanData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> countrywomanItems = [
    { 'id': '0', 'word': loc.translate('meaning'), 'wordSub': loc.translate('meaning_countrywoman'), 'image': 'web/icons/book_icon.png' },
    { 'id': '1', 'word': loc.translate('hand_shape'), 'wordSub': loc.translate('hand_shape_sub'), 'image': 'web/icons/hand.png' },
    { 'id': '2', 'word': loc.translate('action'), 'wordSub': loc.translate('action_sub'), 'image': 'web/icons/hand_move.png' },
  ];
}

class QuestionCardsGenerationData {
  final BuildContext context; QuestionCardsGenerationData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> generationItems = [
    { 'id': '0', 'word': loc.translate('meaning'), 'wordSub': loc.translate('meaning_generation'), 'image': 'web/icons/book_icon.png' },
    { 'id': '1', 'word': loc.translate('hand_shape'), 'wordSub': loc.translate('hand_shape_sub'), 'image': 'web/icons/hand.png' },
    { 'id': '2', 'word': loc.translate('action'), 'wordSub': loc.translate('action_sub'), 'image': 'web/icons/hand_move.png' },
  ];
}

class QuestionCardsDivorceData {
  final BuildContext context; QuestionCardsDivorceData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> divorceItems = [
    { 'id': '0', 'word': loc.translate('meaning'), 'wordSub': loc.translate('meaning_divorce'), 'image': 'web/icons/book_icon.png' },
    { 'id': '1', 'word': loc.translate('hand_shape'), 'wordSub': loc.translate('hand_shape_sub'), 'image': 'web/icons/hand.png' },
    { 'id': '2', 'word': loc.translate('action'), 'wordSub': loc.translate('action_sub'), 'image': 'web/icons/hand_move.png' },
  ];
}

class QuestionCardsChildData {
  final BuildContext context; QuestionCardsChildData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> childItems = [
    { 'id': '0', 'word': loc.translate('meaning'), 'wordSub': loc.translate('meaning_child'), 'image': 'web/icons/book_icon.png' },
    { 'id': '1', 'word': loc.translate('hand_shape'), 'wordSub': loc.translate('hand_shape_sub'), 'image': 'web/icons/hand.png' },
    { 'id': '2', 'word': loc.translate('action'), 'wordSub': loc.translate('action_sub'), 'image': 'web/icons/hand_move.png' },
  ];
}

class QuestionCardsGrandparentsData {
  final BuildContext context; QuestionCardsGrandparentsData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> grandparentsItems = [
    { 'id': '0', 'word': loc.translate('meaning'), 'wordSub': loc.translate('meaning_grandparents'), 'image': 'web/icons/book_icon.png' },
    { 'id': '1', 'word': loc.translate('hand_shape'), 'wordSub': loc.translate('hand_shape_sub'), 'image': 'web/icons/hand.png' },
    { 'id': '2', 'word': loc.translate('action'), 'wordSub': loc.translate('action_sub'), 'image': 'web/icons/hand_move.png' },
  ];
}

class QuestionCardsYoungerBrotherData {
  final BuildContext context; QuestionCardsYoungerBrotherData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> youngerBrotherItems = [
    { 'id': '0', 'word': loc.translate('meaning'), 'wordSub': loc.translate('meaning_younger_brother'), 'image': 'web/icons/book_icon.png' },
    { 'id': '1', 'word': loc.translate('hand_shape'), 'wordSub': loc.translate('hand_shape_sub'), 'image': 'web/icons/hand.png' },
    { 'id': '2', 'word': loc.translate('action'), 'wordSub': loc.translate('action_sub'), 'image': 'web/icons/hand_move.png' },
  ];
}

class QuestionCardsYoungerSisterData {
  final BuildContext context; QuestionCardsYoungerSisterData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> youngerSisterItems = [
    { 'id': '0', 'word': loc.translate('meaning'), 'wordSub': loc.translate('meaning_younger_sister'), 'image': 'web/icons/book_icon.png' },
    { 'id': '1', 'word': loc.translate('hand_shape'), 'wordSub': loc.translate('hand_shape_sub'), 'image': 'web/icons/hand.png' },
    { 'id': '2', 'word': loc.translate('action'), 'wordSub': loc.translate('action_sub'), 'image': 'web/icons/hand_move.png' },
  ];
}

class QuestionCardsElderBrotherData {
  final BuildContext context; QuestionCardsElderBrotherData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> elderBrotherItems = [
    { 'id': '0', 'word': loc.translate('meaning'), 'wordSub': loc.translate('meaning_elder_brother'), 'image': 'web/icons/book_icon.png' },
    { 'id': '1', 'word': loc.translate('hand_shape'), 'wordSub': loc.translate('hand_shape_sub'), 'image': 'web/icons/hand.png' },
    { 'id': '2', 'word': loc.translate('action'), 'wordSub': loc.translate('action_sub'), 'image': 'web/icons/hand_move.png' },
  ];
}

class QuestionCardsElderSisterData {
  final BuildContext context; QuestionCardsElderSisterData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> elderSisterItems = [
    { 'id': '0', 'word': loc.translate('meaning'), 'wordSub': loc.translate('meaning_elder_sister'), 'image': 'web/icons/book_icon.png' },
    { 'id': '1', 'word': loc.translate('hand_shape'), 'wordSub': loc.translate('hand_shape_sub'), 'image': 'web/icons/hand.png' },
    { 'id': '2', 'word': loc.translate('action'), 'wordSub': loc.translate('action_sub'), 'image': 'web/icons/hand_move.png' },
  ];
}

class QuestionCardsBachelorData {
  final BuildContext context; QuestionCardsBachelorData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> bachelorItems = [
    { 'id': '0', 'word': loc.translate('meaning'), 'wordSub': loc.translate('meaning_elder_sister'), 'image': 'web/icons/book_icon.png' },
    { 'id': '1', 'word': loc.translate('hand_shape'), 'wordSub': loc.translate('hand_shape_sub'), 'image': 'web/icons/hand.png' },
    { 'id': '2', 'word': loc.translate('action'), 'wordSub': loc.translate('action_sub'), 'image': 'web/icons/hand_move.png' },
  ];
}

class QuestionCardsGrownUpData {
  final BuildContext context; QuestionCardsGrownUpData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> grownUpItems = [
    { 'id': '0', 'word': loc.translate('meaning'), 'wordSub': loc.translate('meaning_grown_up'), 'image': 'web/icons/book_icon.png' },
    { 'id': '1', 'word': loc.translate('hand_shape'), 'wordSub': loc.translate('hand_shape_sub'), 'image': 'web/icons/hand.png' },
    { 'id': '2', 'word': loc.translate('action'), 'wordSub': loc.translate('action_sub'), 'image': 'web/icons/hand_move.png' },
  ];
}

class QuestionCardsElderData {
  final BuildContext context; QuestionCardsElderData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> elderItems = [
    { 'id': '0', 'word': loc.translate('meaning'), 'wordSub': loc.translate('meaning_elder'), 'image': 'web/icons/book_icon.png' },
    { 'id': '1', 'word': loc.translate('hand_shape'), 'wordSub': loc.translate('hand_shape_sub'), 'image': 'web/icons/hand.png' },
    { 'id': '2', 'word': loc.translate('action'), 'wordSub': loc.translate('action_sub'), 'image': 'web/icons/hand_move.png' },
  ];
}

class QuestionCardsYoungerData {
  final BuildContext context; QuestionCardsYoungerData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> youngerItems = [
    { 'id': '0', 'word': loc.translate('meaning'), 'wordSub': loc.translate('meaning_younger'), 'image': 'web/icons/book_icon.png' },
    { 'id': '1', 'word': loc.translate('hand_shape'), 'wordSub': loc.translate('hand_shape_sub'), 'image': 'web/icons/hand.png' },
    { 'id': '2', 'word': loc.translate('action'), 'wordSub': loc.translate('action_sub'), 'image': 'web/icons/hand_move.png' },
  ];
}

class QuestionCardsOldData {
  final BuildContext context; QuestionCardsOldData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> oldItems = [
    { 'id': '0', 'word': loc.translate('meaning'), 'wordSub': loc.translate('meaning_old'), 'image': 'web/icons/book_icon.png' },
    { 'id': '1', 'word': loc.translate('hand_shape'), 'wordSub': loc.translate('hand_shape_sub'), 'image': 'web/icons/hand.png' },
    { 'id': '2', 'word': loc.translate('action'), 'wordSub': loc.translate('action_sub'), 'image': 'web/icons/hand_move.png' },
  ];
}

class QuestionCardsAdultData {
  final BuildContext context; QuestionCardsAdultData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> adultItems = [
    { 'id': '0', 'word': loc.translate('meaning'), 'wordSub': loc.translate('meaning_adult'), 'image': 'web/icons/book_icon.png' },
    { 'id': '1', 'word': loc.translate('hand_shape'), 'wordSub': loc.translate('hand_shape_sub'), 'image': 'web/icons/hand.png' },
    { 'id': '2', 'word': loc.translate('action'), 'wordSub': loc.translate('action_sub'), 'image': 'web/icons/hand_move.png' },
  ];
}

class QuestionCardsLoverData {
  final BuildContext context; QuestionCardsLoverData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> loverItems = [
    { 'id': '0', 'word': loc.translate('meaning'), 'wordSub': loc.translate('meaning_lover'), 'image': 'web/icons/book_icon.png' },
    { 'id': '1', 'word': loc.translate('hand_shape'), 'wordSub': loc.translate('hand_shape_sub'), 'image': 'web/icons/hand.png' },
    { 'id': '2', 'word': loc.translate('action'), 'wordSub': loc.translate('action_sub'), 'image': 'web/icons/hand_move.png' },
  ];
}

class QuestionCardsTwinSisterData {
  final BuildContext context; QuestionCardsTwinSisterData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> twinSisterItems = [
    { 'id': '0', 'word': loc.translate('meaning'), 'wordSub': loc.translate('meaning_twin_sister'), 'image': 'web/icons/book_icon.png' },
    { 'id': '1', 'word': loc.translate('hand_shape'), 'wordSub': loc.translate('hand_shape_sub'), 'image': 'web/icons/hand.png' },
    { 'id': '2', 'word': loc.translate('action'), 'wordSub': loc.translate('action_sub'), 'image': 'web/icons/hand_move.png' },
  ];
}

class QuestionCardsTwinBrotherData {
  final BuildContext context; QuestionCardsTwinBrotherData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> twinBrotherItems = [
    { 'id': '0', 'word': loc.translate('meaning'), 'wordSub': loc.translate('meaning_twin_brother'), 'image': 'web/icons/book_icon.png' },
    { 'id': '1', 'word': loc.translate('hand_shape'), 'wordSub': loc.translate('hand_shape_sub'), 'image': 'web/icons/hand.png' },
    { 'id': '2', 'word': loc.translate('action'), 'wordSub': loc.translate('action_sub'), 'image': 'web/icons/hand_move.png' },
  ];
}

class QuestionCardsYoungData {
  final BuildContext context; QuestionCardsYoungData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> youngItems = [
    { 'id': '0', 'word': loc.translate('meaning'), 'wordSub': loc.translate('meaning_young'), 'image': 'web/icons/book_icon.png' },
    { 'id': '1', 'word': loc.translate('hand_shape'), 'wordSub': loc.translate('hand_shape_sub'), 'image': 'web/icons/hand.png' },
    { 'id': '2', 'word': loc.translate('action'), 'wordSub': loc.translate('action_sub'), 'image': 'web/icons/hand_move.png' },
  ];
}

class QuestionCardsToLiveData {
  final BuildContext context; QuestionCardsToLiveData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> toLiveItems = [
    { 'id': '0', 'word': loc.translate('meaning'), 'wordSub': loc.translate('meaning_to_live'), 'image': 'web/icons/book_icon.png' },
    { 'id': '1', 'word': loc.translate('hand_shape'), 'wordSub': loc.translate('hand_shape_sub'), 'image': 'web/icons/hand.png' },
    { 'id': '2', 'word': loc.translate('action'), 'wordSub': loc.translate('action_sub'), 'image': 'web/icons/hand_move.png' },
  ];
}

class QuestionCardsDeathData {
  final BuildContext context; QuestionCardsDeathData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> deathItems = [
    { 'id': '0', 'word': loc.translate('meaning'), 'wordSub': loc.translate('meaning_death'), 'image': 'web/icons/book_icon.png' },
    { 'id': '1', 'word': loc.translate('hand_shape'), 'wordSub': loc.translate('hand_shape_sub'), 'image': 'web/icons/hand.png' },
    { 'id': '2', 'word': loc.translate('action'), 'wordSub': loc.translate('action_sub'), 'image': 'web/icons/hand_move.png' },
  ];
}

class QuestionCardsToBeBornData {
  final BuildContext context; QuestionCardsToBeBornData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> toBeBornItems = [
    { 'id': '0', 'word': loc.translate('meaning'), 'wordSub': loc.translate('meaning_to_be_born'), 'image': 'web/icons/book_icon.png' },
    { 'id': '1', 'word': loc.translate('hand_shape'), 'wordSub': loc.translate('hand_shape_sub'), 'image': 'web/icons/hand.png' },
    { 'id': '2', 'word': loc.translate('action'), 'wordSub': loc.translate('action_sub'), 'image': 'web/icons/hand_move.png' },
  ];
}

class QuestionCardsToDieData {
  final BuildContext context; QuestionCardsToDieData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> toDieItems = [
    { 'id': '0', 'word': loc.translate('meaning'), 'wordSub': loc.translate('meaning_to_die'), 'image': 'web/icons/book_icon.png' },
    { 'id': '1', 'word': loc.translate('hand_shape'), 'wordSub': loc.translate('hand_shape_sub'), 'image': 'web/icons/hand.png' },
    { 'id': '2', 'word': loc.translate('action'), 'wordSub': loc.translate('action_sub'), 'image': 'web/icons/hand_move.png' },
  ];
}

class QuestionCardsToRespectData {
  final BuildContext context; QuestionCardsToRespectData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> toRespectItems = [
    { 'id': '0', 'word': loc.translate('meaning'), 'wordSub': loc.translate('meaning_to_respect'), 'image': 'web/icons/book_icon.png' },
    { 'id': '1', 'word': loc.translate('hand_shape'), 'wordSub': loc.translate('hand_shape_sub'), 'image': 'web/icons/hand.png' },
    { 'id': '2', 'word': loc.translate('action'), 'wordSub': loc.translate('action_sub'), 'image': 'web/icons/hand_move.png' },
  ];
}

class QuestionCardsTallData {
  final BuildContext context; QuestionCardsTallData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> tallItems = [
    { 'id': '0', 'word': loc.translate('meaning'), 'wordSub': loc.translate('meaning_tall'), 'image': 'web/icons/book_icon.png' },
    { 'id': '1', 'word': loc.translate('hand_shape'), 'wordSub': loc.translate('hand_shape_sub'), 'image': 'web/icons/hand.png' },
    { 'id': '2', 'word': loc.translate('action'), 'wordSub': loc.translate('action_sub'), 'image': 'web/icons/hand_move.png' },
  ];
}

class QuestionCardsLittleData {
  final BuildContext context; QuestionCardsLittleData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> littleItems = [
    { 'id': '0', 'word': loc.translate('meaning'), 'wordSub': loc.translate('meaning_little'), 'image': 'web/icons/book_icon.png' },
    { 'id': '1', 'word': loc.translate('hand_shape'), 'wordSub': loc.translate('hand_shape_sub'), 'image': 'web/icons/hand.png' },
    { 'id': '2', 'word': loc.translate('action'), 'wordSub': loc.translate('action_sub'), 'image': 'web/icons/hand_move.png' },
  ];
}

class QuestionCardsThinData {
  final BuildContext context; QuestionCardsThinData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> thinItems = [
    { 'id': '0', 'word': loc.translate('meaning'), 'wordSub': loc.translate('meaning_thin'), 'image': 'web/icons/book_icon.png' },
    { 'id': '1', 'word': loc.translate('hand_shape'), 'wordSub': loc.translate('hand_shape_sub'), 'image': 'web/icons/hand.png' },
    { 'id': '2', 'word': loc.translate('action'), 'wordSub': loc.translate('action_sub'), 'image': 'web/icons/hand_move.png' },
  ];
}

class QuestionCardsThickData {
  final BuildContext context; QuestionCardsThickData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> thickItems = [
    { 'id': '0', 'word': loc.translate('meaning'), 'wordSub': loc.translate('meaning_thick'), 'image': 'web/icons/book_icon.png' },
    { 'id': '1', 'word': loc.translate('hand_shape'), 'wordSub': loc.translate('hand_shape_sub'), 'image': 'web/icons/hand.png' },
    { 'id': '2', 'word': loc.translate('action'), 'wordSub': loc.translate('action_sub'), 'image': 'web/icons/hand_move.png' },
  ];
}

class QuestionCardsIllData {
  final BuildContext context; QuestionCardsIllData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> illItems = [
    { 'id': '0', 'word': loc.translate('meaning'), 'wordSub': loc.translate('meaning_ill'), 'image': 'web/icons/book_icon.png' },
    { 'id': '1', 'word': loc.translate('hand_shape'), 'wordSub': loc.translate('hand_shape_sub'), 'image': 'web/icons/hand.png' },
    { 'id': '2', 'word': loc.translate('action'), 'wordSub': loc.translate('action_sub'), 'image': 'web/icons/hand_move.png' },
  ];
}

class QuestionCardsUnfortunateData {
  final BuildContext context; QuestionCardsUnfortunateData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> unfortunateItems = [
    { 'id': '0', 'word': loc.translate('meaning'), 'wordSub': loc.translate('meaning_unfortunate'), 'image': 'web/icons/book_icon.png' },
    { 'id': '1', 'word': loc.translate('hand_shape'), 'wordSub': loc.translate('hand_shape_sub'), 'image': 'web/icons/hand.png' },
    { 'id': '2', 'word': loc.translate('action'), 'wordSub': loc.translate('action_sub'), 'image': 'web/icons/hand_move.png' },
  ];
}

class QuestionCardsPrettyData {
  final BuildContext context; QuestionCardsPrettyData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> prettyItems = [
    { 'id': '0', 'word': loc.translate('meaning'), 'wordSub': loc.translate('meaning_pretty'), 'image': 'web/icons/book_icon.png' },
    { 'id': '1', 'word': loc.translate('hand_shape'), 'wordSub': loc.translate('hand_shape_sub'), 'image': 'web/icons/hand.png' },
    { 'id': '2', 'word': loc.translate('action'), 'wordSub': loc.translate('action_sub'), 'image': 'web/icons/hand_move.png' },
  ];
}

class QuestionCardsPoorData {
  final BuildContext context; QuestionCardsPoorData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> poorItems = [
    { 'id': '0', 'word': loc.translate('meaning'), 'wordSub': loc.translate('meaning_poor'), 'image': 'web/icons/book_icon.png' },
    { 'id': '1', 'word': loc.translate('hand_shape'), 'wordSub': loc.translate('hand_shape_sub'), 'image': 'web/icons/hand.png' },
    { 'id': '2', 'word': loc.translate('action'), 'wordSub': loc.translate('action_sub'), 'image': 'web/icons/hand_move.png' },
  ];
}

class QuestionCardsRichData {
  final BuildContext context; QuestionCardsRichData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> richItems = [
    { 'id': '0', 'word': loc.translate('meaning'), 'wordSub': loc.translate('meaning_rich'), 'image': 'web/icons/book_icon.png' },
    { 'id': '1', 'word': loc.translate('hand_shape'), 'wordSub': loc.translate('hand_shape_sub'), 'image': 'web/icons/hand.png' },
    { 'id': '2', 'word': loc.translate('action'), 'wordSub': loc.translate('action_sub'), 'image': 'web/icons/hand_move.png' },
  ];
}

class QuestionCardsTwinData {
  final BuildContext context; QuestionCardsTwinData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> twinItems = [
    { 'id': '0', 'word': loc.translate('meaning'), 'wordSub': loc.translate('meaning_twin'), 'image': 'web/icons/book_icon.png' },
    { 'id': '1', 'word': loc.translate('hand_shape'), 'wordSub': loc.translate('hand_shape_sub'), 'image': 'web/icons/hand.png' },
    { 'id': '2', 'word': loc.translate('action'), 'wordSub': loc.translate('action_sub'), 'image': 'web/icons/hand_move.png' },
  ];
}

class QuestionCardsGroomData {
  final BuildContext context; QuestionCardsGroomData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> groomItems = [
    { 'id': '0', 'word': loc.translate('meaning'), 'wordSub': loc.translate('meaning_groom'), 'image': 'web/icons/book_icon.png' },
    { 'id': '1', 'word': loc.translate('hand_shape'), 'wordSub': loc.translate('hand_shape_sub'), 'image': 'web/icons/hand.png' },
    { 'id': '2', 'word': loc.translate('action'), 'wordSub': loc.translate('action_sub'), 'image': 'web/icons/hand_move.png' },
  ];
}

class QuestionCardsWidowData {
  final BuildContext context; QuestionCardsWidowData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> widowItems = [
    { 'id': '0', 'word': loc.translate('meaning'), 'wordSub': loc.translate('meaning_widow'), 'image': 'web/icons/book_icon.png' },
    { 'id': '1', 'word': loc.translate('hand_shape'), 'wordSub': loc.translate('hand_shape_sub'), 'image': 'web/icons/hand.png' },
    { 'id': '2', 'word': loc.translate('action'), 'wordSub': loc.translate('action_sub'), 'image': 'web/icons/hand_move.png' },
  ];
}

class QuestionCardsWidowerData {
  final BuildContext context; QuestionCardsWidowerData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> widowerItems = [
    { 'id': '0', 'word': loc.translate('meaning'), 'wordSub': loc.translate('meaning_widower'), 'image': 'web/icons/book_icon.png' },
    { 'id': '1', 'word': loc.translate('hand_shape'), 'wordSub': loc.translate('hand_shape_sub'), 'image': 'web/icons/hand.png' },
    { 'id': '2', 'word': loc.translate('action'), 'wordSub': loc.translate('action_sub'), 'image': 'web/icons/hand_move.png' },
  ];
}

class QuestionCardsYouthData {
  final BuildContext context; QuestionCardsYouthData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> youthItems = [
    { 'id': '0', 'word': loc.translate('meaning'), 'wordSub': loc.translate('meaning_youth'), 'image': 'web/icons/book_icon.png' },
    { 'id': '1', 'word': loc.translate('hand_shape'), 'wordSub': loc.translate('hand_shape_sub'), 'image': 'web/icons/hand.png' },
    { 'id': '2', 'word': loc.translate('action'), 'wordSub': loc.translate('action_sub'), 'image': 'web/icons/hand_move.png' },
  ];
}

// =======================================================================
// Last Seen
// =======================================================================
class RelatedGesturesData { // family
  final BuildContext context; RelatedGesturesData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> relatedGesturesItem = [
    { 'id': '0', 'image': '', 'word': loc.translate('grandfather') }, { 'id': '1', 'image': '', 'word': loc.translate('grandmother') },
    { 'id': '2', 'image': '', 'word': loc.translate('father') }, { 'id': '3', 'image': '', 'word': loc.translate('mother') },
  ];
}

class RelatedGrandfatherData { // grandfather
  final BuildContext context; RelatedGrandfatherData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> relatedGrandfatherItem = [
    { 'id': '0', 'image': '', 'word': loc.translate('grandmother') }, { 'id': '1', 'image': '', 'word': loc.translate('family') },
    { 'id': '2', 'image': '', 'word': loc.translate('brother') }, { 'id': '3', 'image': '', 'word': loc.translate('sister') },
  ];
}

class RelatedGrandmotherData { // grandmother
  final BuildContext context; RelatedGrandmotherData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> relatedGrandmotherItem = [
    { 'id': '0', 'image': '', 'word': loc.translate('father') }, { 'id': '1', 'image': '', 'word': loc.translate('mother') },
    { 'id': '2', 'image': '', 'word': loc.translate('sister') }, { 'id': '3', 'image': '', 'word': loc.translate('brother') },
  ];
}

class RelatedFatherData { // father
  final BuildContext context; RelatedFatherData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> relatedFatherItem = [
    { 'id': '0', 'image': '', 'word': loc.translate('brother') }, { 'id': '1', 'image': '', 'word': loc.translate('sister') },
    { 'id': '2', 'image': '', 'word': loc.translate('son') }, { 'id': '3', 'image': '', 'word': loc.translate('daughter') },
  ];
}

class RelatedMotherData { // mother
  final BuildContext context; RelatedMotherData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> relatedMotherItem = [
    { 'id': '0', 'image': '', 'word': loc.translate('baby') }, { 'id': '1', 'image': '', 'word': loc.translate('grandfather') },
    { 'id': '2', 'image': '', 'word': loc.translate('father') }, { 'id': '3', 'image': '', 'word': loc.translate('grandmother') },
  ];
}

class RelatedSisterData { // sister
  final BuildContext context; RelatedSisterData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> relatedSisterItem = [
    { 'id': '0', 'image': '', 'word': loc.translate('grandfather') }, { 'id': '1', 'image': '', 'word': loc.translate('father') },
    { 'id': '2', 'image': '', 'word': loc.translate('brother') }, { 'id': '3', 'image': '', 'word': loc.translate('baby') },
  ];
}

class RelatedBrotherData { // brother
  final BuildContext context; RelatedBrotherData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> relatedBrotherItem = [
    { 'id': '0', 'image': '', 'word': loc.translate('grandfather') }, { 'id': '1', 'image': '', 'word': loc.translate('grandmother') },
    { 'id': '2', 'image': '', 'word': loc.translate('mother') }, { 'id': '3', 'image': '', 'word': loc.translate('sister') },
  ];
}

class RelatedBabyData { // baby
  final BuildContext context; RelatedBabyData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> relatedBabyItem = [
    { 'id': '0', 'image': '', 'word': loc.translate('son') }, { 'id': '1', 'image': '', 'word': loc.translate('brother') },
    { 'id': '2', 'image': '', 'word': loc.translate('daughter') }, { 'id': '3', 'image': '', 'word': loc.translate('family') },
  ];
}

class RelatedSonData { // son
  final BuildContext context; RelatedSonData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> relatedSonItem = [
    { 'id': '0', 'image': '', 'word': loc.translate('mother') }, { 'id': '1', 'image': '', 'word': loc.translate('father') },
    { 'id': '2', 'image': '', 'word': loc.translate('sister') }, { 'id': '3', 'image': '', 'word': loc.translate('baby') },
  ];
}

class RelatedDaughterData { // daughter
  final BuildContext context; RelatedDaughterData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> relatedDaughterItem = [
    { 'id': '0', 'image': '', 'word': loc.translate('grandfather') }, { 'id': '1', 'image': '', 'word': loc.translate('brother') },
    { 'id': '2', 'image': '', 'word': loc.translate('son') }, { 'id': '3', 'image': '', 'word': loc.translate('family') },
  ];
}

class RelatedUncleData { // uncle
  final BuildContext context; RelatedUncleData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> relatedUncleItem = [
    { 'id': '0', 'image': '', 'word': loc.translate('aunt') }, { 'id': '1', 'image': '', 'word': loc.translate('niece') },
    { 'id': '2', 'image': '', 'word': loc.translate('cousin') }, { 'id': '3', 'image': '', 'word': loc.translate('nephew') },
  ];
}

class RelatedAuntData { // aunt
  final BuildContext context; RelatedAuntData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> relatedAuntItem = [
    { 'id': '0', 'image': '', 'word': loc.translate('uncle') }, { 'id': '1', 'image': '', 'word': loc.translate('family') },
    { 'id': '2', 'image': '', 'word': loc.translate('niece') }, { 'id': '3', 'image': '', 'word': loc.translate('siblings') },
  ];
}

class RelatedCousinData { // cousin
  final BuildContext context; RelatedCousinData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> relatedCousinItem = [
    { 'id': '0', 'image': '', 'word': loc.translate('parents') }, { 'id': '1', 'image': '', 'word': loc.translate('uncle') },
    { 'id': '2', 'image': '', 'word': loc.translate('siblings') }, { 'id': '3', 'image': '', 'word': loc.translate('children') },
  ];
}

class RelatedNieceData { // niece
  final BuildContext context; RelatedNieceData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> relatedNieceItem = [
    { 'id': '0', 'image': '', 'word': loc.translate('nephew') }, { 'id': '1', 'image': '', 'word': loc.translate('aunt') },
    { 'id': '2', 'image': '', 'word': loc.translate('baby') }, { 'id': '3', 'image': '', 'word': loc.translate('sister') },
  ];
}

class RelatedNephewData { // nephew
  final BuildContext context; RelatedNephewData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> relatedNephewItem = [
    { 'id': '0', 'image': '', 'word': loc.translate('uncle') }, { 'id': '1', 'image': '', 'word': loc.translate('children') },
    { 'id': '2', 'image': '', 'word': loc.translate('brother') }, { 'id': '3', 'image': '', 'word': loc.translate('parents') },
  ];
}

class RelatedParentsData { // parents
  final BuildContext context; RelatedParentsData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> relatedParentsItem = [
    { 'id': '0', 'image': '', 'word': loc.translate('father') }, { 'id': '1', 'image': '', 'word': loc.translate('grandfather') },
    { 'id': '2', 'image': '', 'word': loc.translate('grandmother') }, { 'id': '3', 'image': '', 'word': loc.translate('mother') },
  ];
}

class RelatedSiblingsData { // siblings
  final BuildContext context; RelatedSiblingsData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> relatedSiblingsItem = [
    { 'id': '0', 'image': '', 'word': loc.translate('uncle') }, { 'id': '1', 'image': '', 'word': loc.translate('family') },
    { 'id': '2', 'image': '', 'word': loc.translate('aunt') }, { 'id': '3', 'image': '', 'word': loc.translate('cousin') },
  ];
}

class RelatedChildrenData { // children
  final BuildContext context; RelatedChildrenData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> relatedChildrenItem = [
    { 'id': '0', 'image': '', 'word': loc.translate('niece') }, { 'id': '1', 'image': '', 'word': loc.translate('daughter') },
    { 'id': '2', 'image': '', 'word': loc.translate('son') }, { 'id': '3', 'image': '', 'word': loc.translate('nephew') },
  ];
}

class RelatedHusbandData { // husband
  final BuildContext context; RelatedHusbandData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> relatedHusbandItem = [
    { 'id': '0', 'image': '', 'word': loc.translate('wife') }, { 'id': '1', 'image': '', 'word': loc.translate('boy') },
    { 'id': '2', 'image': '', 'word': loc.translate('person') }, { 'id': '3', 'image': '', 'word': loc.translate('girl') },
  ];
}

class RelatedWifeData { // wife
  final BuildContext context; RelatedWifeData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> relatedWifeItem = [
    { 'id': '0', 'image': '', 'word': loc.translate('man') }, { 'id': '1', 'image': '', 'word': loc.translate('husband') },
    { 'id': '2', 'image': '', 'word': loc.translate('relative') }, { 'id': '3', 'image': '', 'word': loc.translate('woman') },
  ];
}

class RelatedPersonData { // person
  final BuildContext context; RelatedPersonData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> relatedPersonItem = [
    { 'id': '0', 'image': '', 'word': loc.translate('boy') }, { 'id': '1', 'image': '', 'word': loc.translate('wife') },
    { 'id': '2', 'image': '', 'word': loc.translate('girl') }, { 'id': '3', 'image': '', 'word': loc.translate('family') },
  ];
}

class RelatedManData { // man
  final BuildContext context; RelatedManData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> relatedManItem = [
    { 'id': '0', 'image': '', 'word': loc.translate('person') }, { 'id': '1', 'image': '', 'word': loc.translate('relative') },
    { 'id': '2', 'image': '', 'word': loc.translate('husband') }, { 'id': '3', 'image': '', 'word': loc.translate('woman') },
  ];
}

class RelatedWomanData { // woman
  final BuildContext context; RelatedWomanData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> relatedWomanItem = [
    { 'id': '0', 'image': '', 'word': loc.translate('girl') }, { 'id': '1', 'image': '', 'word': loc.translate('person') },
    { 'id': '2', 'image': '', 'word': loc.translate('boy') }, { 'id': '3', 'image': '', 'word': loc.translate('wife') },
  ];
}

class RelatedBoyData { // boy
  final BuildContext context; RelatedBoyData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> relatedBoyItem = [
    { 'id': '0', 'image': '', 'word': loc.translate('husband') }, { 'id': '1', 'image': '', 'word': loc.translate('man') },
    { 'id': '2', 'image': '', 'word': loc.translate('family') }, { 'id': '3', 'image': '', 'word': loc.translate('relative') },
  ];
}

class RelatedGirlData { // girl
  final BuildContext context; RelatedGirlData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> relatedGirlItem = [
    { 'id': '0', 'image': '', 'word': loc.translate('person') }, { 'id': '1', 'image': '', 'word': loc.translate('woman') },
    { 'id': '2', 'image': '', 'word': loc.translate('wife') }, { 'id': '3', 'image': '', 'word': loc.translate('boy') },
  ];
}

class RelatedRelativeData { // relative
  final BuildContext context; RelatedRelativeData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> relatedRelativeItem = [
    { 'id': '0', 'image': '', 'word': loc.translate('boy') }, { 'id': '1', 'image': '', 'word': loc.translate('man') },
    { 'id': '2', 'image': '', 'word': loc.translate('girl') }, { 'id': '3', 'image': '', 'word': loc.translate('family') },
  ];
}

class RelatedMarriageData { // marriage
  final BuildContext context; RelatedMarriageData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> relatedMarriageItem = [
    { 'id': '0', 'image': '', 'word': loc.translate('bride') }, { 'id': '1', 'image': '', 'word': loc.translate('countrywoman') },
    { 'id': '2', 'image': '', 'word': loc.translate('spouse') }, { 'id': '3', 'image': '', 'word': loc.translate('teenager') },
  ];
}

class RelatedBrideData { // bride
  final BuildContext context; RelatedBrideData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> relatedBrideItem = [
    { 'id': '0', 'image': '', 'word': loc.translate('generation') }, { 'id': '1', 'image': '', 'word': loc.translate('divorce') },
    { 'id': '2', 'image': '', 'word': loc.translate('spouse') }, { 'id': '3', 'image': '', 'word': loc.translate('person') },
  ];
}

class RelatedSpouseData { // spouse
  final BuildContext context; RelatedSpouseData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> relatedSpouseItem = [
    { 'id': '0', 'image': '', 'word': loc.translate('marriage') }, { 'id': '1', 'image': '', 'word': loc.translate('teenager') },
    { 'id': '2', 'image': '', 'word': loc.translate('countrywoman') }, { 'id': '3', 'image': '', 'word': loc.translate('bride') },
  ];
}

class RelatedTeenagerData { // teenager
  final BuildContext context; RelatedTeenagerData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> relatedTeenagerItem = [
    { 'id': '0', 'image': '', 'word': loc.translate('parents') }, { 'id': '1', 'image': '', 'word': loc.translate('generation') },
    { 'id': '2', 'image': '', 'word': loc.translate('divorce') }, { 'id': '3', 'image': '', 'word': loc.translate('spouse') },
  ];
}

class RelatedCountrywomanData { // countrywoman
  final BuildContext context; RelatedCountrywomanData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> relatedCountrywomanItem = [
    { 'id': '0', 'image': '', 'word': loc.translate('woman') }, { 'id': '1', 'image': '', 'word': loc.translate('grandmother') },
    { 'id': '2', 'image': '', 'word': loc.translate('teenager') }, { 'id': '3', 'image': '', 'word': loc.translate('generation') },
  ];
}

class RelatedGenerationData { // generation
  final BuildContext context; RelatedGenerationData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> relatedGenerationItem = [
    { 'id': '0', 'image': '', 'word': loc.translate('relative') }, { 'id': '1', 'image': '', 'word': loc.translate('marriage') },
    { 'id': '2', 'image': '', 'word': loc.translate('spouse') }, { 'id': '3', 'image': '', 'word': loc.translate('divorce') },
  ];
}

class RelatedDivorceData { // divorce
  final BuildContext context; RelatedDivorceData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> relatedDivorceItem = [
    { 'id': '0', 'image': '', 'word': loc.translate('marriage') }, { 'id': '1', 'image': '', 'word': loc.translate('teenager') },
    { 'id': '2', 'image': '', 'word': loc.translate('generation') }, { 'id': '3', 'image': '', 'word': loc.translate('bride') },
  ];
}

class RelatedChildData { // child
  final BuildContext context; RelatedChildData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> relatedChildItem = [
    { 'id': '0', 'image': '', 'word': loc.translate('grandfather') }, { 'id': '1', 'image': '', 'word': loc.translate('younger_brother') },
    { 'id': '2', 'image': '', 'word': loc.translate('grandparents') }, { 'id': '3', 'image': '', 'word': loc.translate('grandmother') },
  ];
}

class RelatedGrandparentsData { // grandparents
  final BuildContext context; RelatedGrandparentsData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> relatedGrandparentsItem = [
    { 'id': '0', 'image': '', 'word': loc.translate('younger_sister') }, { 'id': '1', 'image': '', 'word': loc.translate('elder_sister') },
    { 'id': '2', 'image': '', 'word': loc.translate('elder_brother') }, { 'id': '3', 'image': '', 'word': loc.translate('child') },
  ];
}

class RelatedYoungerBrotherData { // younger brother
  final BuildContext context; RelatedYoungerBrotherData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> relatedYoungerBrotherItem = [
    { 'id': '0', 'image': '', 'word': loc.translate('bachelor') }, { 'id': '1', 'image': '', 'word': loc.translate('elder_sister') },
    { 'id': '2', 'image': '', 'word': loc.translate('grandparents') }, { 'id': '3', 'image': '', 'word': loc.translate('divorce') },
  ];
}

class RelatedYoungerSisterData { // younger sister
  final BuildContext context; RelatedYoungerSisterData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> relatedYoungerSisterItem = [
    { 'id': '0', 'image': '', 'word': loc.translate('child') }, { 'id': '1', 'image': '', 'word': loc.translate('younger_brother') },
    { 'id': '2', 'image': '', 'word': loc.translate('generation') }, { 'id': '3', 'image': '', 'word': loc.translate('elder_brother') },
  ];
}

class RelatedElderBrotherData { // elder brother
  final BuildContext context; RelatedElderBrotherData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> relatedElderBrotherItem = [
    { 'id': '0', 'image': '', 'word': loc.translate('younger_sister') }, { 'id': '1', 'image': '', 'word': loc.translate('child') },
    { 'id': '2', 'image': '', 'word': loc.translate('divorce') }, { 'id': '3', 'image': '', 'word': loc.translate('bachelor') },
  ];
}

class RelatedElderSisterData { // elder sister
  final BuildContext context; RelatedElderSisterData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> relatedElderSisterItem = [
    { 'id': '0', 'image': '', 'word': loc.translate('younger_sister') }, { 'id': '1', 'image': '', 'word': loc.translate('spouse') },
    { 'id': '2', 'image': '', 'word': loc.translate('countrywoman') }, { 'id': '3', 'image': '', 'word': loc.translate('grandparents') },
  ];
}

class RelatedBachelorData { // bachelor
  final BuildContext context; RelatedBachelorData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> relatedBachelorItem = [
    { 'id': '0', 'image': '', 'word': loc.translate('younger_brother') }, { 'id': '1', 'image': '', 'word': loc.translate('elder_brother') },
    { 'id': '2', 'image': '', 'word': loc.translate('child') }, { 'id': '3', 'image': '', 'word': loc.translate('elder_sister') },
  ];
}

class RelatedGrownUpData { // grown up
  final BuildContext context; RelatedGrownUpData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> relatedGrownUpItem = [
    { 'id': '0', 'image': '', 'word': loc.translate('elder') }, { 'id': '1', 'image': '', 'word': loc.translate('younger') },
    { 'id': '2', 'image': '', 'word': loc.translate('old') }, { 'id': '3', 'image': '', 'word': loc.translate('adult') },
  ];
}

class RelatedElderData { // elder
  final BuildContext context; RelatedElderData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> relatedElderItem = [
    { 'id': '0', 'image': '', 'word': loc.translate('lover') }, { 'id': '1', 'image': '', 'word': loc.translate('twin_brother') },
    { 'id': '2', 'image': '', 'word': loc.translate('twin_sister') }, { 'id': '3', 'image': '', 'word': loc.translate('grown_up') },
  ];
}

class RelatedYoungerData { // younger
  final BuildContext context; RelatedYoungerData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> relatedYoungerItem = [
    { 'id': '0', 'image': '', 'word': loc.translate('grown_up') }, { 'id': '1', 'image': '', 'word': loc.translate('lover') },
    { 'id': '2', 'image': '', 'word': loc.translate('adult') }, { 'id': '3', 'image': '', 'word': loc.translate('elder') },
  ];
}

class RelatedOldData { // old
  final BuildContext context; RelatedOldData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> relatedOldItem = [
    { 'id': '0', 'image': '', 'word': loc.translate('bachelor') }, { 'id': '1', 'image': '', 'word': loc.translate('twin_brother') },
    { 'id': '2', 'image': '', 'word': loc.translate('young') }, { 'id': '3', 'image': '', 'word': loc.translate('twin_sister') },
  ];
}

class RelatedAdultData { // adult
  final BuildContext context; RelatedAdultData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> relatedAdultItem = [
    { 'id': '0', 'image': '', 'word': loc.translate('old') }, { 'id': '1', 'image': '', 'word': loc.translate('younger') },
    { 'id': '2', 'image': '', 'word': loc.translate('elder') }, { 'id': '3', 'image': '', 'word': loc.translate('lover') },
  ];
}

class RelatedLoverData { // lover
  final BuildContext context; RelatedLoverData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> relatedLoverItem = [
    { 'id': '0', 'image': '', 'word': loc.translate('grown_up') }, { 'id': '1', 'image': '', 'word': loc.translate('adult') },
    { 'id': '2', 'image': '', 'word': loc.translate('younger') }, { 'id': '3', 'image': '', 'word': loc.translate('old') },
  ];
}

class RelatedTwinSisterData { // twin sister
  final BuildContext context; RelatedTwinSisterData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> relatedTwinSisterItem = [
    { 'id': '0', 'image': '', 'word': loc.translate('old') }, { 'id': '1', 'image': '', 'word': loc.translate('twin_brother') },
    { 'id': '2', 'image': '', 'word': loc.translate('elder') }, { 'id': '3', 'image': '', 'word': loc.translate('lover') },
  ];
}

class RelatedTwinBrotherData { // adult
  final BuildContext context; RelatedTwinBrotherData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> relatedTwinBrotherItem = [
    { 'id': '0', 'image': '', 'word': loc.translate('adult') }, { 'id': '1', 'image': '', 'word': loc.translate('grown_up') },
    { 'id': '2', 'image': '', 'word': loc.translate('lover') }, { 'id': '3', 'image': '', 'word': loc.translate('twin_sister') },
  ];
}

class RelatedYoungData { // young
  final BuildContext context; RelatedYoungData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> relatedYoungItem = [
    { 'id': '0', 'image': '', 'word': loc.translate('old') }, { 'id': '1', 'image': '', 'word': loc.translate('elder') },
    { 'id': '2', 'image': '', 'word': loc.translate('younger') }, { 'id': '3', 'image': '', 'word': loc.translate('adult') },
  ];
}

class RelatedToLiveData { // to live
  final BuildContext context; RelatedToLiveData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> relatedToLiveItem = [
    { 'id': '0', 'image': '', 'word': loc.translate('death') }, { 'id': '1', 'image': '', 'word': loc.translate('to_be_born') },
    { 'id': '2', 'image': '', 'word': loc.translate('to_die') }, { 'id': '3', 'image': '', 'word': loc.translate('siblings') },
  ];
}

class RelatedDeathData { // death
  final BuildContext context; RelatedDeathData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> relatedDeathItem = [
    { 'id': '0', 'image': '', 'word': loc.translate('to_die') }, { 'id': '1', 'image': '', 'word': loc.translate('to_live') },
    { 'id': '2', 'image': '', 'word': loc.translate('teenager') }, { 'id': '3', 'image': '', 'word': loc.translate('to_respect') },
  ];
}

class RelatedToBeBornData { // to be born
  final BuildContext context; RelatedToBeBornData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> relatedToBeBornItem = [
    { 'id': '0', 'image': '', 'word': loc.translate('to_live') }, { 'id': '1', 'image': '', 'word': loc.translate('Young') },
    { 'id': '2', 'image': '', 'word': loc.translate('to_respect') }, { 'id': '3', 'image': '', 'word': loc.translate('child') },
  ];
}

class RelatedToDieData { // to die
  final BuildContext context; RelatedToDieData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> relatedToDieItem = [
    { 'id': '0', 'image': '', 'word': loc.translate('to_be_born') }, { 'id': '1', 'image': '', 'word': loc.translate('to_respect') },
    { 'id': '2', 'image': '', 'word': loc.translate('death') }, { 'id': '3', 'image': '', 'word': loc.translate('to_live') },
  ];
}

class RelatedToRespectData { // to respect
  final BuildContext context; RelatedToRespectData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> relatedToRespectItem = [
    { 'id': '0', 'image': '', 'word': loc.translate('tall') }, { 'id': '1', 'image': '', 'word': loc.translate('little') },
    { 'id': '2', 'image': '', 'word': loc.translate('thin') }, { 'id': '3', 'image': '', 'word': loc.translate('thick') },
  ];
}

class RelatedTallData { // tall
  final BuildContext context; RelatedTallData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> relatedTallItem = [
    { 'id': '0', 'image': '', 'word': loc.translate('adult') }, { 'id': '1', 'image': '', 'word': loc.translate('to_respect') },
    { 'id': '2', 'image': '', 'word': loc.translate('old') }, { 'id': '3', 'image': '', 'word': loc.translate('ill') },
  ];
}

class RelatedLittleData { // little
  final BuildContext context; RelatedLittleData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> relatedLittleItem = [
    { 'id': '0', 'image': '', 'word': loc.translate('child') }, { 'id': '1', 'image': '', 'word': loc.translate('children') },
    { 'id': '2', 'image': '', 'word': loc.translate('tall') }, { 'id': '3', 'image': '', 'word': loc.translate('baby') },
  ];
}

class RelatedThinData { // thin
  final BuildContext context; RelatedThinData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> relatedThinItem = [
    { 'id': '0', 'image': '', 'word': loc.translate('thick') }, { 'id': '1', 'image': '', 'word': loc.translate('ill') },
    { 'id': '2', 'image': '', 'word': loc.translate('to_respect') }, { 'id': '3', 'image': '', 'word': loc.translate('little') },
  ];
}

class RelatedThickData { // thick
  final BuildContext context; RelatedThickData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> relatedThickItem = [
    { 'id': '0', 'image': '', 'word': loc.translate('to_live') }, { 'id': '1', 'image': '', 'word': loc.translate('thin') },
    { 'id': '2', 'image': '', 'word': loc.translate('to_respect') }, { 'id': '3', 'image': '', 'word': loc.translate('tall') },
  ];
}

class RelatedIllData { // ill
  final BuildContext context; RelatedIllData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> relatedIllItem = [
    { 'id': '0', 'image': '', 'word': loc.translate('poor') }, { 'id': '1', 'image': '', 'word': loc.translate('pretty') },
    { 'id': '2', 'image': '', 'word': loc.translate('rich') }, { 'id': '3', 'image': '', 'word': loc.translate('unfortunate') },
  ];
}

class RelatedUnfortunateData { // unfortunate
  final BuildContext context; RelatedUnfortunateData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> relatedUnfortunateItem = [
    { 'id': '0', 'image': '', 'word': loc.translate('ill') }, { 'id': '1', 'image': '', 'word': loc.translate('tall') },
    { 'id': '2', 'image': '', 'word': loc.translate('adult') }, { 'id': '3', 'image': '', 'word': loc.translate('poor') },
  ];
}

class RelatedPrettyData { // pretty
  final BuildContext context; RelatedPrettyData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> relatedPrettyItem = [
    { 'id': '0', 'image': '', 'word': loc.translate('family') }, { 'id': '1', 'image': '', 'word': loc.translate('grandparents') },
    { 'id': '2', 'image': '', 'word': loc.translate('to_live') }, { 'id': '3', 'image': '', 'word': loc.translate('siblings') },
  ];
}

class RelatedPoorData { // poor
  final BuildContext context; RelatedPoorData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> relatedPoorItem = [
    { 'id': '0', 'image': '', 'word': loc.translate('old') }, { 'id': '1', 'image': '', 'word': loc.translate('to_die') },
    { 'id': '2', 'image': '', 'word': loc.translate('death') }, { 'id': '3', 'image': '', 'word': loc.translate('divorce') },
  ];
}

class RelatedRichData { // rich
  final BuildContext context; RelatedRichData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> relatedRichItem = [
    { 'id': '0', 'image': '', 'word': loc.translate('parents') }, { 'id': '1', 'image': '', 'word': loc.translate('family') },
    { 'id': '2', 'image': '', 'word': loc.translate('to_respect') }, { 'id': '3', 'image': '', 'word': loc.translate('poor') },
  ];
}

class RelatedTwinData { // twin
  final BuildContext context; RelatedTwinData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> relatedTwinItem = [
    { 'id': '0', 'image': '', 'word': loc.translate('boy') }, { 'id': '1', 'image': '', 'word': loc.translate('younger_sister') },
    { 'id': '2', 'image': '', 'word': loc.translate('younger_brother') }, { 'id': '3', 'image': '', 'word': loc.translate('girl') },
  ];
}

class RelatedGroomData { // groom
  final BuildContext context; RelatedGroomData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> relatedGroomItem = [
    { 'id': '0', 'image': '', 'word': loc.translate('bride') }, { 'id': '1', 'image': '', 'word': loc.translate('rich') },
    { 'id': '2', 'image': '', 'word': loc.translate('lover') }, { 'id': '3', 'image': '', 'word': loc.translate('marriage') },
  ];
}


class RelatedWidowData { // widow
  final BuildContext context; RelatedWidowData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> relatedWidowItem = [
    { 'id': '0', 'image': '', 'word': loc.translate('widower') }, { 'id': '1', 'image': '', 'word': loc.translate('to_die') },
    { 'id': '2', 'image': '', 'word': loc.translate('adult') }, { 'id': '3', 'image': '', 'word': loc.translate('to_live') },
  ];
}

class RelatedWidowerData { // widower
  final BuildContext context; RelatedWidowerData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> relatedWidowerItem = [
    { 'id': '0', 'image': '', 'word': loc.translate('grown_up') }, { 'id': '1', 'image': '', 'word': loc.translate('to_die') },
    { 'id': '2', 'image': '', 'word': loc.translate('adult') }, { 'id': '3', 'image': '', 'word': loc.translate('widow') },
  ];
}

class RelatedYouthData { // youth
  final BuildContext context; RelatedYouthData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> relatedYouthItem = [
    { 'id': '0', 'image': '', 'word': loc.translate('to_respect') }, { 'id': '1', 'image': '', 'word': loc.translate('unfortunate') },
    { 'id': '2', 'image': '', 'word': loc.translate('poor') }, { 'id': '3', 'image': '', 'word': loc.translate('to_live') },
  ];
}
