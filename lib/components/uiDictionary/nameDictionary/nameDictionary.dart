import 'package:flutter/cupertino.dart';
import 'package:signlang/l10n/app_localizations.dart';

// =======================================================================
// Dictionary cards
// =======================================================================
class DictionaryCardsData {
  final BuildContext context; DictionaryCardsData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late List<Map<String, dynamic>> dictionaryCardsItems = [
    { 'id': '0', 'image': 'web/icons/all.png', 'icon': 'solar:widget-4-linear', 'title': loc.translate('all') }, { 'id': '1', 'image': 'web/icons/family_icon.png', 'icon': 'solar:users-group-rounded-linear', 'title': loc.translate('family') },
    { 'id': '2', 'image': 'web/icons/sausage.png', 'icon': 'solar:donut-bitten-linear', 'title': loc.translate('food') }, { 'id': '3', 'image': 'web/icons/code.png', 'icon': 'solar:hashtag-linear', 'title': loc.translate('numbers') },
    { 'id': '4', 'image': 'web/icons/capsule.png', 'icon': 'solar:pills-linear', 'title': loc.translate('medicine') }, { 'id': '5', 'image': 'web/icons/alphabet_icons.png', 'icon': 'solar:text-square-linear', 'title': loc.translate('alphabet') },
    { 'id': '6', 'image': 'web/icons/transports.png', 'icon': 'solar:bus-linear', 'title': loc.translate('transportation') }, { 'id': '7', 'image': 'web/icons/public_services.png', 'icon': 'solar:buildings-2-linear', 'title': loc.translate('public_services')},
    { 'id': '8', 'image': 'web/icons/sports.png', 'icon': 'solar:basketball-linear', 'title': loc.translate('sports')},
  ];
  List<Map<String, dynamic>> get dictionaryCardsList => dictionaryCardsItems;
}

class StoresDictionaryCardsData {
  final BuildContext context; StoresDictionaryCardsData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late List<Map<String, dynamic>> allItems = [
    { 'id': '0', 'image': 'web/icons/alphabet_icons.png', 'icon': 'solar:text-square-linear', 'title': loc.translate('alphabet'), 'title_sub': '28 ${loc.translate('alphabet_sub')}' },
    { 'id': '1', 'image': 'web/icons/family_icon.png', 'icon': 'solar:users-group-rounded-linear', 'title': loc.translate('family'), 'title_sub': '32 ${loc.translate('words')}' },
    { 'id': '2', 'image': 'web/icons/code.png', 'icon': 'solar:hashtag-linear', 'title': loc.translate('numbers'), 'title_sub': '100 ${loc.translate('numbers')}' },
    { 'id': '3', 'image': 'web/icons/capsule.png', 'icon': 'solar:pills-linear', 'title': loc.translate('medicine'), 'title_sub': '18 ${loc.translate('daily_life_sub')}' },
    { 'id': '4', 'image': 'web/icons/healthy_food.png', 'icon': 'solar:donut-bitten-linear', 'title': loc.translate('food'), 'title_sub': '32 ${loc.translate('food_sub')}' },
    { 'id': '5', 'image': 'web/icons/emoticons.png', 'icon': 'solar:emoji-funny-circle-linear', 'title': loc.translate('feelings'), 'title_sub': '24 ${loc.translate('feelings_sub')}' },
    { 'id': '6', 'image': 'web/icons/lifestyle.png', 'icon': 'solar:home-smile-linear', 'title': loc.translate('daily_life'), 'title_sub': '32 ${loc.translate('daily_life_sub')}' },
    { 'id': '7', 'image': 'web/icons/transportation_icon.png', 'icon': 'solar:bus-linear', 'title': loc.translate('transportation'), 'title_sub': '23 ${loc.translate('transportation_sub')}' },
    { 'id': '8', 'image': 'web/icons/museum.png', 'icon': 'solar:buildings-2-linear', 'title': loc.translate('public_services'), 'title_sub': '32 ${loc.translate('public_services_sub')}' },
    { 'id': '9', 'image': 'web/icons/sports_icon.png', 'icon': 'solar:basketball-linear', 'title': loc.translate('sports'), 'title_sub': '18 ${loc.translate('sports_sub')}' },
  ];

  late List<Map<String, dynamic>> familyItems = [
    { 'id': '0', 'image': '', 'title': loc.translate('words_sub_1'), 'title_sub': '26 ${loc.translate('words')}' },
    { 'id': '1', 'image': '', 'title': loc.translate('words_sub_2'), 'title_sub': '21 ${loc.translate('words')}' },
    { 'id': '2', 'image': '', 'title': loc.translate('words_sub_3'), 'title_sub': '18 ${loc.translate('words')}' },
    { 'id': '3', 'image': '', 'title': loc.translate('words_sub_4'), 'title_sub': '12 ${loc.translate('words')}' },
    { 'id': '4', 'image': '', 'title': loc.translate('words_sub_5'), 'title_sub': '24 ${loc.translate('words')}' },
  ];

  late List<Map<String, dynamic>> foodItems = [
    { 'id': '0', 'image': '', 'title': loc.translate('food'), 'title_sub': "17 ${loc.translate('words')}" },
    { 'id': '1', 'image': '', 'title': loc.translate('fruit'), 'title_sub': "19 ${loc.translate('words')}" },
    { 'id': '2', 'image': '', 'title': loc.translate('vegetables'), 'title_sub': "26 ${loc.translate('words')}" },
    { 'id': '3', 'image': '', 'title': loc.translate('cereals'), 'title_sub': "22 ${loc.translate('words')}" },
    { 'id': '4', 'image': '', 'title': loc.translate('dairy'), 'title_sub': "27 ${loc.translate('words')}" },
  ];

  late List<Map<String, dynamic>> numbersItems = [
    { 'id': '0', 'image': '', 'title': "${loc.translate('zero')} and ${loc.translate('nine')}", 'title_sub': "0 - 9 ${loc.translate('numbers')}" },
    { 'id': '1', 'image': '', 'title': "${loc.translate('ten')} and ${loc.translate('nineteen')}", 'title_sub': "10 - 19 ${loc.translate('numbers')}" },
    { 'id': '2', 'image': '', 'title': "${loc.translate('twenty')} and ${loc.translate('one_hundred')}", 'title_sub': "20 - 100 ${loc.translate('numbers')}" },
    { 'id': '3', 'image': '', 'title': "${loc.translate('two_hundred')} and ${loc.translate('thousand')}", 'title_sub': "200 - ${loc.translate('thousand')} ${loc.translate('numbers')}" },
    { 'id': '4', 'image': '', 'title': "${loc.translate('two_thousand')} and ${loc.translate('third')}", 'title_sub': "2000 - ${loc.translate('third')} ${loc.translate('numbers')}" },
  ];

  late List<Map<String, dynamic>> medicItems = [
    { 'id': '0', 'image': '', 'title': loc.translate('hospital'), 'title_sub': loc.translate('') },
    { 'id': '1', 'image': '', 'title': loc.translate('clinic'), 'title_sub': loc.translate('') },
    { 'id': '2', 'image': '', 'title': loc.translate('hospital_bed'), 'title_sub': loc.translate('') },
    { 'id': '3', 'image': '', 'title': loc.translate('wheelchair'), 'title_sub': loc.translate('') },
    { 'id': '4', 'image': '', 'title': loc.translate('stretcher'), 'title_sub': loc.translate('') },
    { 'id': '5', 'image': '', 'title': loc.translate('stethoscope'), 'title_sub': loc.translate('') },
    { 'id': '6', 'image': '', 'title': loc.translate('thermometer'), 'title_sub': loc.translate('') },
    { 'id': '7', 'image': '', 'title': loc.translate('blood_pressure_monitor'), 'title_sub': loc.translate('') },
    { 'id': '8', 'image': '', 'title': loc.translate('face_mask'), 'title_sub': loc.translate('') },
    { 'id': '9', 'image': '', 'title': loc.translate('medical_gloves'), 'title_sub': loc.translate('') },
    { 'id': '10', 'image': '', 'title': loc.translate('medical_gown'), 'title_sub': loc.translate('') },
    { 'id': '11', 'image': '', 'title': loc.translate('syringe'), 'title_sub': loc.translate('') },
    { 'id': '12', 'image': '', 'title': loc.translate('iv_drip'), 'title_sub': loc.translate('') },
    { 'id': '13', 'image': '', 'title': loc.translate('oxygen_cylinder'), 'title_sub': loc.translate('') },
    { 'id': '14', 'image': '', 'title': loc.translate('oxygen_mask'), 'title_sub': loc.translate('') },
    { 'id': '15', 'image': '', 'title': loc.translate('first_aid_kit'), 'title_sub': loc.translate('') },
    { 'id': '16', 'image': '', 'title': loc.translate('crutches'), 'title_sub': loc.translate('') },
    { 'id': '17', 'image': '', 'title': loc.translate('walking_cane'), 'title_sub': loc.translate('') },
    { 'id': '18', 'image': '', 'title': loc.translate('x_ray_machine'), 'title_sub': loc.translate('') },
    { 'id': '19', 'image': '', 'title': loc.translate('ultrasound_machine'), 'title_sub': loc.translate('') },
    { 'id': '20', 'image': '', 'title': loc.translate('ecg_machine'), 'title_sub': loc.translate('') },
    { 'id': '21', 'image': '', 'title': loc.translate('emergency_hospital'), 'title_sub': loc.translate('') },
    { 'id': '22', 'image': '', 'title': loc.translate('children_hospital'), 'title_sub': loc.translate('') },
    { 'id': '23', 'image': '', 'title': loc.translate('maternity_hospital'), 'title_sub': loc.translate('') },
    { 'id': '24', 'image': '', 'title': loc.translate('private_hospital'), 'title_sub': loc.translate('') },
    { 'id': '25', 'image': '', 'title': loc.translate('public_hospital'), 'title_sub': loc.translate('') },
    { 'id': '26', 'image': '', 'title': loc.translate('central_hospital'), 'title_sub': loc.translate('') },
    { 'id': '27', 'image': '', 'title': loc.translate('city_hospital'), 'title_sub': loc.translate('') },
    { 'id': '28', 'image': '', 'title': loc.translate('district_hospital'), 'title_sub': loc.translate('') },
    { 'id': '29', 'image': '', 'title': loc.translate('specialized_hospital'), 'title_sub': loc.translate('') },
    { 'id': '30', 'image': '', 'title': loc.translate('medical_center'), 'title_sub': loc.translate('') },
    { 'id': '31', 'image': '', 'title': loc.translate('emergency_medical_center'), 'title_sub': loc.translate('') },
    { 'id': '32', 'image': '', 'title': loc.translate('oncology_center'), 'title_sub': loc.translate('') },
    { 'id': '33', 'image': '', 'title': loc.translate('cardiology_center'), 'title_sub': loc.translate('') },
    { 'id': '34', 'image': '', 'title': loc.translate('surgical_center'), 'title_sub': loc.translate('') },
    { 'id': '35', 'image': '', 'title': loc.translate('dental_clinic'), 'title_sub': loc.translate('') },
    { 'id': '36', 'image': '', 'title': loc.translate('medicine'), 'title_sub': loc.translate('') },
    { 'id': '37', 'image': '', 'title': loc.translate('pill'), 'title_sub': loc.translate('') },
    { 'id': '38', 'image': '', 'title': loc.translate('tablet'), 'title_sub': loc.translate('') },
    { 'id': '39', 'image': '', 'title': loc.translate('capsule'), 'title_sub': loc.translate('') },
    { 'id': '40', 'image': '', 'title': loc.translate('syrup'), 'title_sub': loc.translate('') },
    { 'id': '41', 'image': '', 'title': loc.translate('vitamin'), 'title_sub': loc.translate('') },
    { 'id': '42', 'image': '', 'title': loc.translate('antibiotic'), 'title_sub': loc.translate('') },
    { 'id': '43', 'image': '', 'title': loc.translate('painkiller'), 'title_sub': loc.translate('') },
    { 'id': '44', 'image': '', 'title': loc.translate('ointment'), 'title_sub': loc.translate('') },
    { 'id': '45', 'image': '', 'title': loc.translate('cream'), 'title_sub': loc.translate('') },
    { 'id': '46', 'image': '', 'title': loc.translate('drops'), 'title_sub': loc.translate('') },
    { 'id': '47', 'image': '', 'title': loc.translate('inhaler'), 'title_sub': loc.translate('') },
    { 'id': '48', 'image': '', 'title': loc.translate('injection'), 'title_sub': loc.translate('') },
    { 'id': '49', 'image': '', 'title': loc.translate('bandage'), 'title_sub': loc.translate('') },
    { 'id': '50', 'image': '', 'title': loc.translate('plaster'), 'title_sub': loc.translate('') },
    { 'id': '51', 'image': '', 'title': loc.translate('antiseptic'), 'title_sub': loc.translate('') },
    { 'id': '52', 'image': '', 'title': loc.translate('prescription'), 'title_sub': loc.translate('') },
    { 'id': '53', 'image': '', 'title': loc.translate('vaccine'), 'title_sub': loc.translate('') },
    { 'id': '54', 'image': '', 'title': loc.translate('doctor'), 'title_sub': loc.translate('') },
    { 'id': '55', 'image': '', 'title': loc.translate('nurse'), 'title_sub': loc.translate('') },
    { 'id': '56', 'image': '', 'title': loc.translate('fever'), 'title_sub': loc.translate('') },
    { 'id': '57', 'image': '', 'title': loc.translate('pain'), 'title_sub': loc.translate('') },
    { 'id': '58', 'image': '', 'title': loc.translate('cough'), 'title_sub': loc.translate('') },
    { 'id': '59', 'image': '', 'title': loc.translate('blood'), 'title_sub': loc.translate('') },
    { 'id': '60', 'image': '', 'title': loc.translate('wound'), 'title_sub': loc.translate('') },
    { 'id': '61', 'image': '', 'title': loc.translate('surgery'), 'title_sub': loc.translate('') },
  ];

  late List<Map<String, dynamic>> alpItems = [
    { 'id': '0', 'image': '', 'title': loc.translate('a'), 'title_sub': loc.translate('') },
    { 'id': '0', 'image': '', 'title': loc.translate('b'), 'title_sub': loc.translate('') },
    { 'id': '0', 'image': '', 'title': loc.translate('d'), 'title_sub': loc.translate('') },
    { 'id': '0', 'image': '', 'title': loc.translate('e'), 'title_sub': loc.translate('') },
    { 'id': '0', 'image': '', 'title': loc.translate('f'), 'title_sub': loc.translate('') },
    { 'id': '0', 'image': '', 'title': loc.translate('g'), 'title_sub': loc.translate('') },
    { 'id': '0', 'image': '', 'title': loc.translate('h'), 'title_sub': loc.translate('') },
    { 'id': '0', 'image': '', 'title': loc.translate('i'), 'title_sub': loc.translate('') },
    { 'id': '0', 'image': '', 'title': loc.translate('j'), 'title_sub': loc.translate('') },
    { 'id': '0', 'image': '', 'title': loc.translate('k'), 'title_sub': loc.translate('') },
    { 'id': '0', 'image': '', 'title': loc.translate('l'), 'title_sub': loc.translate('') },
    { 'id': '0', 'image': '', 'title': loc.translate('m'), 'title_sub': loc.translate('') },
    { 'id': '0', 'image': '', 'title': loc.translate('n'), 'title_sub': loc.translate('') },
    { 'id': '0', 'image': '', 'title': loc.translate('o'), 'title_sub': loc.translate('') },
    { 'id': '0', 'image': '', 'title': loc.translate('p'), 'title_sub': loc.translate('') },
    { 'id': '0', 'image': '', 'title': loc.translate('q'), 'title_sub': loc.translate('') },
    { 'id': '0', 'image': '', 'title': loc.translate('r'), 'title_sub': loc.translate('') },
    { 'id': '0', 'image': '', 'title': loc.translate('s'), 'title_sub': loc.translate('') },
    { 'id': '0', 'image': '', 'title': loc.translate('t'), 'title_sub': loc.translate('') },
    { 'id': '0', 'image': '', 'title': loc.translate('u'), 'title_sub': loc.translate('') },
    { 'id': '0', 'image': '', 'title': loc.translate('v'), 'title_sub': loc.translate('') },
    { 'id': '0', 'image': '', 'title': loc.translate('x'), 'title_sub': loc.translate('') },
    { 'id': '0', 'image': '', 'title': loc.translate('y'), 'title_sub': loc.translate('') },
    { 'id': '0', 'image': '', 'title': loc.translate('z'), 'title_sub': loc.translate('') },
    { 'id': '0', 'image': '', 'title': loc.translate("o'"), 'title_sub': loc.translate('') },
    { 'id': '0', 'image': '', 'title': loc.translate("g'"), 'title_sub': loc.translate('') },
    { 'id': '0', 'image': '', 'title': loc.translate('sh'), 'title_sub': loc.translate('') },
    { 'id': '0', 'image': '', 'title': loc.translate('ch'), 'title_sub': loc.translate('') },
  ];

  late List<Map<String, dynamic>> tranItems = [];

  late List<Map<String, dynamic>> pubItems = [];

  late List<Map<String, dynamic>> spoItems = [];

  Map<String, List<Map<String, dynamic>>> get storesDictionaryCardsByCategory => {
    '0': allItems, '1': familyItems, '2': foodItems, '3': numbersItems, '4': medicItems, '5': alpItems, '6': tranItems, '7': pubItems, '8': spoItems
  };
}

// =======================================================================
// Search Words to download
// =======================================================================
class DownloadData {
  final BuildContext context; DownloadData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> downloadItems = [
    { 'key': loc.translate('complete_dictionary'), 'size': '184 MB', 'status': 'pending', 'progress': 0.0, 'image': 'web/icons/book_icon.png' },
    { 'key': loc.translate('emergency_phrases'), 'size': '24 MB', 'status': 'pending', 'progress': 0.0, 'image': 'web/icons/emergency.png' },
    { 'key': loc.translate('example_sentences'), 'size': '42 MB', 'status': 'pending', 'progress': 0.0, 'image': 'web/icons/save_icon.png' },
  ];
}

// =======================================================================
// Last Seen
// =======================================================================
class LastSeenData {
  final BuildContext context; LastSeenData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> lastSeenItems = [
    { 'id': '0', 'word': loc.translate('hello'), 'image': 'web/sign_lang_image/five.png' },
    { 'id': '1', 'word': loc.translate('five'), 'image': 'web/sign_lang_image/five.png' },
    { 'id': '2', 'word': loc.translate('two'), 'image': 'web/sign_lang_image/five.png' },
  ];
}

// =======================================================================
// Search Words
// =======================================================================
class ResultsData {
  final BuildContext context; ResultsData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> resultsItems = [
    // =========== Alphabet ===========
    { 'id': '0', 'image': 'web/sign_lang_image/level_a.png', 'word': loc.translate('a'), 'phonetic': '[${loc.translate('a')}]', 'type': 'word' },
    { 'id': '1', 'image': '', 'word': loc.translate('b'), 'phonetic': '[${loc.translate('b')}]', 'type': 'word' },
    { 'id': '2', 'image': '', 'word': loc.translate('d'), 'phonetic': '[${loc.translate('d')}]', 'type': 'word' },
    { 'id': '3', 'image': '', 'word': loc.translate('e'), 'phonetic': '[${loc.translate('e')}]', 'type': 'word' },
    { 'id': '4', 'image': '', 'word': loc.translate('f'), 'phonetic': '[${loc.translate('f')}]', 'type': 'word' },
    { 'id': '5', 'image': '', 'word': loc.translate('g'), 'phonetic': '[${loc.translate('g')}]', 'type': 'word' },
    { 'id': '6', 'image': '', 'word': loc.translate('h'), 'phonetic': '[${loc.translate('h')}]', 'type': 'word' },
    { 'id': '7', 'image': '', 'word': loc.translate('i'), 'phonetic': '[${loc.translate('i')}]', 'type': 'word' },
    { 'id': '8', 'image': '', 'word': loc.translate('j'), 'phonetic': '[${loc.translate('j')}]', 'type': 'word' },
    { 'id': '9', 'image': '', 'word': loc.translate('k'), 'phonetic': '[${loc.translate('k')}]', 'type': 'word' },
    { 'id': '10', 'image': '', 'word': loc.translate('l'), 'phonetic': '[${loc.translate('l')}]', 'type': 'word' },
    { 'id': '11', 'image': '', 'word': loc.translate('m'), 'phonetic': '[${loc.translate('m')}]', 'type': 'word' },
    { 'id': '12', 'image': '', 'word': loc.translate('n'), 'phonetic': '[${loc.translate('n')}]', 'type': 'word' },
    { 'id': '13', 'image': '', 'word': loc.translate('o'), 'phonetic': '[${loc.translate('o')}]', 'type': 'word' },
    { 'id': '14', 'image': '', 'word': loc.translate('p'), 'phonetic': '[${loc.translate('p')}]', 'type': 'word' },
    { 'id': '15', 'image': '', 'word': loc.translate('q'), 'phonetic': '[${loc.translate('q')}]', 'type': 'word' },
    { 'id': '16', 'image': '', 'word': loc.translate('r'), 'phonetic': '[${loc.translate('r')}]', 'type': 'word' },
    { 'id': '17', 'image': '', 'word': loc.translate('s'), 'phonetic': '[${loc.translate('s')}]', 'type': 'word' },
    { 'id': '18', 'image': '', 'word': loc.translate('t'), 'phonetic': '[${loc.translate('t')}]', 'type': 'word' },
    { 'id': '19', 'image': '', 'word': loc.translate('u'), 'phonetic': '[${loc.translate('u')}]', 'type': 'word' },
    { 'id': '20', 'image': '', 'word': loc.translate('v'), 'phonetic': '[${loc.translate('v')}]', 'type': 'word' },
    { 'id': '21', 'image': '', 'word': loc.translate('x'), 'phonetic': '[${loc.translate('x')}]', 'type': 'word' },
    { 'id': '22', 'image': '', 'word': loc.translate('y'), 'phonetic': '[${loc.translate('y')}]', 'type': 'word' },
    { 'id': '23', 'image': '', 'word': loc.translate('z'), 'phonetic': '[${loc.translate('z')}]', 'type': 'word' },
    { 'id': '24', 'image': '', 'word': loc.translate("o'"), 'phonetic': '[${loc.translate("o'")}]', 'type': 'word' },
    { 'id': '25', 'image': '', 'word': loc.translate("g'"), 'phonetic': '[${loc.translate("g'")}]', 'type': 'word' },
    { 'id': '26', 'image': '', 'word': loc.translate('sh'), 'phonetic': '[${loc.translate('sh')}]', 'type': 'word' },
    { 'id': '27', 'image': '', 'word': loc.translate('ch'), 'phonetic': '[${loc.translate('ch')}]', 'type': 'word' },

    // =========== Numbers Level ===========
    { 'id': '28', 'image': 'web/sign_lang_image/num_1.png', 'word': loc.translate('one'), 'phonetic': '[${loc.translate('one_phrases')}]', 'type': 'word' },
    { 'id': '29', 'image': 'web/sign_lang_image/num_2.png', 'word': loc.translate('two'), 'phonetic': '[${loc.translate('two_phrases')}]', 'type': 'word' },
    { 'id': '30', 'image': 'web/sign_lang_image/num_3.png', 'word': loc.translate('three'), 'phonetic': '[${loc.translate('three_phrases')}]', 'type': 'word' },
    { 'id': '31', 'image': 'web/sign_lang_image/num_4.png', 'word': loc.translate('four'), 'phonetic': '[${loc.translate('four_phrases')}]', 'type': 'word' },
    { 'id': '32', 'image': 'web/sign_lang_image/num_5.png', 'word': loc.translate('five'), 'phonetic': '[${loc.translate('five_phrases')}]', 'type': 'word' },
    { 'id': '33', 'image': 'web/sign_lang_image/num_6.png', 'word': loc.translate('six'), 'phonetic': '[${loc.translate('six_phrases')}]', 'type': 'word' },
    { 'id': '34', 'image': 'web/sign_lang_image/num_7.png', 'word': loc.translate('seven'), 'phonetic': '[${loc.translate('seven_phrases')}]', 'type': 'word' },
    { 'id': '35', 'image': 'web/sign_lang_image/num_8.png', 'word': loc.translate('eight'), 'phonetic': '[${loc.translate('eight_phrases')}]', 'type': 'word' },
    { 'id': '36', 'image': 'web/sign_lang_image/num_9.png', 'word': loc.translate('nine'), 'phonetic': '[${loc.translate('nine_phrases')}]', 'type': 'word' },
    { 'id': '37', 'image': 'web/sign_lang_image/num_10.png', 'word': loc.translate('ten'), 'phonetic': '[${loc.translate('ten_phrases')}]', 'type': 'word' },
    { 'id': '38', 'image': 'web/sign_lang_image/num_11.png', 'word': loc.translate('eleven'), 'phonetic': '[${loc.translate('eleven_phrases')}]', 'type': 'word' },
    { 'id': '39', 'image': 'web/sign_lang_image/num_12.png', 'word': loc.translate('twelve'), 'phonetic': '[${loc.translate('twelve_phrases')}]', 'type': 'word' },
    { 'id': '40', 'image': 'web/sign_lang_image/num_13.png', 'word': loc.translate('thirteen'), 'phonetic': '[${loc.translate('thirteen_phrases')}]', 'type': 'word' },
    { 'id': '41', 'image': 'web/sign_lang_image/num_14.png', 'word': loc.translate('fourteen'), 'phonetic': '[${loc.translate('fourteen_phrases')}]', 'type': 'word' },
    { 'id': '42', 'image': 'web/sign_lang_image/num_15.png', 'word': loc.translate('fifteen'), 'phonetic': '[${loc.translate('fifteen_phrases')}]', 'type': 'word' },
    { 'id': '43', 'image': 'web/sign_lang_image/num_16.png', 'word': loc.translate('sixteen'), 'phonetic': '[${loc.translate('sixteen_phrases')}]', 'type': 'word' },
    { 'id': '44', 'image': 'web/sign_lang_image/num_17.png', 'word': loc.translate('seventeen'), 'phonetic': '[${loc.translate('seventeen_phrases')}]', 'type': 'word' },
    { 'id': '45', 'image': '', 'word': loc.translate('eighteen'), 'phonetic': '[${loc.translate('eighteen_phrases')}]', 'type': 'word' },
    { 'id': '46', 'image': '', 'word': loc.translate('nineteen'), 'phonetic': '[${loc.translate('nineteen_phrases')}]', 'type': 'word' },
    { 'id': '47', 'image': '', 'word': loc.translate('twenty'), 'phonetic': '[${loc.translate('twenty_phrases')}]', 'type': 'word' },
    { 'id': '57', 'image': '', 'word': loc.translate('thirty'), 'phonetic': '[${loc.translate('thirty_phrases')}]', 'type': 'word' },
    { 'id': '67', 'image': '', 'word': loc.translate('forty'), 'phonetic': '[${loc.translate('forty_phrases')}]', 'type': 'word' },
    { 'id': '77', 'image': '', 'word': loc.translate('fifty'), 'phonetic': '[${loc.translate('fifty_phrases')}]', 'type': 'word' },
    { 'id': '87', 'image': '', 'word': loc.translate('sixty'), 'phonetic': '[${loc.translate('sixty_phrases')}]', 'type': 'word' },
    { 'id': '97', 'image': '', 'word': loc.translate('seventy'), 'phonetic': '[${loc.translate('seventy_phrases')}]', 'type': 'word' },
    { 'id': '107', 'image': '', 'word': loc.translate('eighty'), 'phonetic': '[${loc.translate('eighty_phrases')}]', 'type': 'word' },
    { 'id': '117', 'image': '', 'word': loc.translate('ninety'), 'phonetic': '[${loc.translate('ninety_phrases')}]', 'type': 'word' },
    { 'id': '127', 'image': '', 'word': loc.translate('one_hundred'), 'phonetic': '[${loc.translate('one_hundred_phrases')}]', 'type': 'word' },
    { 'id': '128', 'image': '', 'word': loc.translate('two_hundred'), 'phonetic': '[${loc.translate('two_hundred_phrases')}]', 'type': 'word' },
    { 'id': '129', 'image': '', 'word': loc.translate('three_hundred'), 'phonetic': '[${loc.translate('three_hundred_phrases')}]', 'type': 'word' },
    { 'id': '130', 'image': '', 'word': loc.translate('four_hundred'), 'phonetic': '[${loc.translate('four_hundred_phrases')}]', 'type': 'word' },
    { 'id': '131', 'image': '', 'word': loc.translate('five_hundred'), 'phonetic': '[${loc.translate('five_hundred_phrases')}]', 'type': 'word' },
    { 'id': '132', 'image': '', 'word': loc.translate('six_hundred'), 'phonetic': '[${loc.translate('six_hundred_phrases')}]', 'type': 'word' },
    { 'id': '134', 'image': '', 'word': loc.translate('seven_hundred'), 'phonetic': '[${loc.translate('seven_hundred_phrases')}]', 'type': 'word' },
    { 'id': '135', 'image': '', 'word': loc.translate('eight_hundred'), 'phonetic': '[${loc.translate('eight_hundred_phrases')}]', 'type': 'word' },
    { 'id': '136', 'image': '', 'word': loc.translate('nine_hundred'), 'phonetic': '[${loc.translate('nine_hundred_phrases')}]', 'type': 'word' },
    { 'id': '137', 'image': '', 'word': loc.translate('thousand'), 'phonetic': '[${loc.translate('thousand_phrases')}]', 'type': 'word' },
    { 'id': '137', 'image': '', 'word': loc.translate('one_thousand'), 'phonetic': '[${loc.translate('one_thousand_phrases')}]', 'type': 'word' },
    { 'id': '137', 'image': '', 'word': loc.translate('two_thousand'), 'phonetic': '[${loc.translate('two_thousand_phrases')}]', 'type': 'word' },
    { 'id': '137', 'image': '', 'word': loc.translate('three_thousand'), 'phonetic': '[${loc.translate('three_thousand_phrases')}]', 'type': 'word' },
    { 'id': '137', 'image': '', 'word': loc.translate('four_thousand'), 'phonetic': '[${loc.translate('four_thousand_phrases')}]', 'type': 'word' },
    { 'id': '137', 'image': '', 'word': loc.translate('five_thousand'), 'phonetic': '[${loc.translate('five_thousand_phrases')}]', 'type': 'word' },
    { 'id': '138', 'image': '', 'word': loc.translate('one_million'), 'phonetic': '[${loc.translate('million_phrases')}]', 'type': 'word' },
    { 'id': '140', 'image': 'web/sign_lang_image/num_0.png', 'word': loc.translate('zero'), 'phonetic': '[${loc.translate('zero_phrases')}]', 'type': 'word' },
    { 'id': '141', 'image': '', 'word': loc.translate('first'), 'phonetic': '[${loc.translate('first_phrases')}]', 'type': 'word' },
    { 'id': '142', 'image': '', 'word': loc.translate('second'), 'phonetic': '[${loc.translate('second_phrases')}]', 'type': 'word' },
    { 'id': '142', 'image': '', 'word': loc.translate('third'), 'phonetic': '[${loc.translate('third_phrases')}]', 'type': 'word' },

    // =========== Family ===========
    { 'id': '143', 'image': '', 'word': loc.translate('father'), 'phonetic': '[${loc.translate('father_phrases')}]', 'type': 'word' },
    { 'id': '144', 'image': '', 'word': loc.translate('mother'), 'phonetic': '[${loc.translate('mother_phrases')}]', 'type': 'word' },
    { 'id': '145', 'image': '', 'word': loc.translate('parents'), 'phonetic': '[${loc.translate('parents_phrases')}]', 'type': 'word' },
    { 'id': '146', 'image': '', 'word': loc.translate('brother'), 'phonetic': '[${loc.translate('brother_phrases')}]', 'type': 'word' },
    { 'id': '147', 'image': '', 'word': loc.translate('sister'), 'phonetic': '[${loc.translate('sister_phrases')}]', 'type': 'word' },
    { 'id': '148', 'image': '', 'word': loc.translate('siblings'), 'phonetic': '[${loc.translate('siblings_phrases')}]', 'type': 'word' },
    { 'id': '149', 'image': '', 'word': loc.translate('son'), 'phonetic': '[${loc.translate('son_phrases')}]', 'type': 'word' },
    { 'id': '150', 'image': '', 'word': loc.translate('daughter'), 'phonetic': '[${loc.translate('daughter_phrases')}]', 'type': 'word' },
    { 'id': '151', 'image': '', 'word': loc.translate('children'), 'phonetic': '[${loc.translate('children_phrases')}]', 'type': 'word' },
    { 'id': '152', 'image': '', 'word': loc.translate('child'), 'phonetic': '[${loc.translate('child_phrases')}]', 'type': 'word' },
    { 'id': '153', 'image': '', 'word': loc.translate('baby'), 'phonetic': '[${loc.translate('baby_phrases')}]', 'type': 'word' },
    { 'id': '154', 'image': '', 'word': loc.translate('elder_brother'), 'phonetic': '[${loc.translate('elder_brother_phrases')}]', 'type': 'word' },
    { 'id': '155', 'image': '', 'word': loc.translate('elder_sister'), 'phonetic': '[${loc.translate('elder_sister_phrases')}]', 'type': 'word' },
    { 'id': '156', 'image': '', 'word': loc.translate('younger_brother'), 'phonetic': '[${loc.translate('younger_brother_phrases')}]', 'type': 'word' },
    { 'id': '157', 'image': '', 'word': loc.translate('younger_sister'), 'phonetic': '[${loc.translate('younger_sister_phrases')}]', 'type': 'word' },
    { 'id': '158', 'image': '', 'word': loc.translate('person'), 'phonetic': '[${loc.translate('person_phrases')}]', 'type': 'word' },
    { 'id': '159', 'image': '', 'word': loc.translate('man'), 'phonetic': '[${loc.translate('man_phrases')}]', 'type': 'word' },
    { 'id': '160', 'image': '', 'word': loc.translate('woman'), 'phonetic': '[${loc.translate('woman_phrases')}]', 'type': 'word' },
    { 'id': '161', 'image': '', 'word': loc.translate('boy'), 'phonetic': '[${loc.translate('boy_phrases')}]', 'type': 'word' },
    { 'id': '162', 'image': '', 'word': loc.translate('girl'), 'phonetic': '[${loc.translate('girl_phrases')}]', 'type': 'word' },
    { 'id': '163', 'image': '', 'word': loc.translate('twin'), 'phonetic': '[${loc.translate('twin_phrases')}]', 'type': 'word' },
    { 'id': '164', 'image': '', 'word': loc.translate('twin_brother'), 'phonetic': '[${loc.translate('twin_brother_phrases')}]', 'type': 'word' },
    { 'id': '165', 'image': '', 'word': loc.translate('twin_sister'), 'phonetic': '[${loc.translate('twin_sister_phrases')}]', 'type': 'word' },
    { 'id': '166', 'image': '', 'word': loc.translate('grandfather'), 'phonetic': '[${loc.translate('grandfather_phrases')}]', 'type': 'word' },
    { 'id': '167', 'image': '', 'word': loc.translate('grandmother'), 'phonetic': '[${loc.translate('grandmother_phrases')}]', 'type': 'word' },
    { 'id': '168', 'image': '', 'word': loc.translate('grandparents'), 'phonetic': '[${loc.translate('grandparents_phrases')}]', 'type': 'word' },
    { 'id': '169', 'image': '', 'word': loc.translate('uncle'), 'phonetic': '[${loc.translate('uncle_phrases')}]', 'type': 'word' },
    { 'id': '170', 'image': '', 'word': loc.translate('aunt'), 'phonetic': '[${loc.translate('aunt_phrases')}]', 'type': 'word' },
    { 'id': '171', 'image': '', 'word': loc.translate('cousin'), 'phonetic': '[${loc.translate('cousin_phrases')}]', 'type': 'word' },
    { 'id': '172', 'image': '', 'word': loc.translate('niece'), 'phonetic': '[${loc.translate('niece_phrases')}]', 'type': 'word' },
    { 'id': '173', 'image': '', 'word': loc.translate('nephew'), 'phonetic': '[${loc.translate('nephew_phrases')}]', 'type': 'word' },
    { 'id': '174', 'image': '', 'word': loc.translate('relative'), 'phonetic': '[${loc.translate('relative_phrases')}]', 'type': 'word' },
    { 'id': '175', 'image': '', 'word': loc.translate('countrywoman'), 'phonetic': '[${loc.translate('countrywoman_phrases')}]', 'type': 'word' },
    { 'id': '176', 'image': '', 'word': loc.translate('generation'), 'phonetic': '[${loc.translate('generation_phrases')}]', 'type': 'word' },
    { 'id': '177', 'image': '', 'word': loc.translate('teenager'), 'phonetic': '[${loc.translate('teenager_phrases')}]', 'type': 'word' },
    { 'id': '178', 'image': '', 'word': loc.translate('bride'), 'phonetic': '[${loc.translate('bride_phrases')}]', 'type': 'word' },
    { 'id': '179', 'image': '', 'word': loc.translate('groom'), 'phonetic': '[${loc.translate('groom_phrases')}]', 'type': 'word' },
    { 'id': '180', 'image': '', 'word': loc.translate('marriage'), 'phonetic': '[${loc.translate('marriage_phrases')}]', 'type': 'word' },
    { 'id': '181', 'image': '', 'word': loc.translate('spouse'), 'phonetic': '[${loc.translate('spouse_phrases')}]', 'type': 'word' },
    { 'id': '182', 'image': '', 'word': loc.translate('divorce'), 'phonetic': '[${loc.translate('divorce_phrases')}]', 'type': 'word' },
    { 'id': '183', 'image': '', 'word': loc.translate('bachelor'), 'phonetic': '[${loc.translate('bachelor_phrases')}]', 'type': 'word' },
    { 'id': '184', 'image': '', 'word': loc.translate('lover'), 'phonetic': '[${loc.translate('lover_phrases')}]', 'type': 'word' },
    { 'id': '185', 'image': '', 'word': loc.translate('pretty'), 'phonetic': '[${loc.translate('pretty_phrases')}]', 'type': 'word' },
    { 'id': '186', 'image': '', 'word': loc.translate('husband'), 'phonetic': '[${loc.translate('husband_phrases')}]', 'type': 'word' },
    { 'id': '187', 'image': '', 'word': loc.translate('wife'), 'phonetic': '[${loc.translate('wife_phrases')}]', 'type': 'word' },
    { 'id': '188', 'image': '', 'word': loc.translate('family'), 'phonetic': '[${loc.translate('family_phrases')}]', 'type': 'word' },
    { 'id': '189', 'image': '', 'word': loc.translate('youth'), 'phonetic': '[${loc.translate('youth_phrases')}]', 'type': 'word' },
    { 'id': '190', 'image': '', 'word': loc.translate('unfortunate'), 'phonetic': '[${loc.translate('unfortunate_phrases')}]', 'type': 'word' },
    { 'id': '191', 'image': '', 'word': loc.translate('rich'), 'phonetic': '[${loc.translate('rich_phrases')}]', 'type': 'word' },
    { 'id': '192', 'image': '', 'word': loc.translate('poor'), 'phonetic': '[${loc.translate('poor_phrases')}]', 'type': 'word' },
    { 'id': '193', 'image': '', 'word': loc.translate('to_respect'), 'phonetic': '[${loc.translate('to_respect_phrases')}]', 'type': 'word' },
    { 'id': '194', 'image': '', 'word': loc.translate('to_live'), 'phonetic': '[${loc.translate('to_live_phrases')}]', 'type': 'word' },
    { 'id': '195', 'image': '', 'word': loc.translate('grown_up'), 'phonetic': '[${loc.translate('grown_up_phrases')}]', 'type': 'word' },
    { 'id': '196', 'image': '', 'word': loc.translate('adult'), 'phonetic': '[${loc.translate('adult_phrases')}]', 'type': 'word' },
    { 'id': '197', 'image': '', 'word': loc.translate('elder'), 'phonetic': '[${loc.translate('elder_phrases')}]', 'type': 'word' },
    { 'id': '198', 'image': '', 'word': loc.translate('younger'), 'phonetic': '[${loc.translate('younger_phrases')}]', 'type': 'word' },
    { 'id': '199', 'image': '', 'word': loc.translate('widow'), 'phonetic': '[${loc.translate('widow_phrases')}]', 'type': 'word' },
    { 'id': '200', 'image': '', 'word': loc.translate('widower'), 'phonetic': '[${loc.translate('widower_phrases')}]', 'type': 'word' },
    { 'id': '201', 'image': '', 'word': loc.translate('to_be_born'), 'phonetic': '[${loc.translate('to_be_born_phrases')}]', 'type': 'word' },
    { 'id': '202', 'image': '', 'word': loc.translate('tall'), 'phonetic': '[${loc.translate('tall_phrases')}]', 'type': 'word' },
    { 'id': '203', 'image': '', 'word': loc.translate('little'), 'phonetic': '[${loc.translate('little_phrases')}]', 'type': 'word' },
    { 'id': '204', 'image': '', 'word': loc.translate('thick'), 'phonetic': '[${loc.translate('thick_phrases')}]', 'type': 'word' },
    { 'id': '205', 'image': '', 'word': loc.translate('ill'), 'phonetic': '[${loc.translate('ill_phrases')}]', 'type': 'word' },
    { 'id': '206', 'image': '', 'word': loc.translate('thin'), 'phonetic': '[${loc.translate('thin_phrases')}]', 'type': 'word' },
    { 'id': '207', 'image': '', 'word': loc.translate('young'), 'phonetic': '[${loc.translate('young_phrases')}]', 'type': 'word' },
    { 'id': '208', 'image': '', 'word': loc.translate('death'), 'phonetic': '[${loc.translate('death_phrases')}]', 'type': 'word' },
    { 'id': '209', 'image': '', 'word': loc.translate('to_die'), 'phonetic': '[${loc.translate('to_die_phrases')}]', 'type': 'word' },

    // =========== Food ===========
    { 'id': '210', 'image': '', 'word': loc.translate('food'), 'phonetic': '[${loc.translate('food_phrases')}]', 'type': 'word' },
    { 'id': '211', 'image': '', 'word': loc.translate('soup'), 'phonetic': '[${loc.translate('soup_phrases')}]', 'type': 'word' },
    { 'id': '212', 'image': '', 'word': loc.translate('pilaf'), 'phonetic': '[${loc.translate('pilaf_phrases')}]', 'type': 'word' },
    { 'id': '213', 'image': '', 'word': loc.translate('rice_pilaf'), 'phonetic': '[${loc.translate('rice_pilaf_phrases')}]', 'type': 'word' },
    { 'id': '214', 'image': '', 'word': loc.translate('samosa'), 'phonetic': '[${loc.translate('samosa_phrases')}]', 'type': 'word' },
    { 'id': '215', 'image': '', 'word': loc.translate('steamed_dumplings'), 'phonetic': '[${loc.translate('steamed_dumplings_phrases')}]', 'type': 'word' },
    { 'id': '216', 'image': '', 'word': loc.translate('dumplings'), 'phonetic': '[${loc.translate('dumplings_phrases')}]', 'type': 'word' },
    { 'id': '217', 'image': '', 'word': loc.translate('kebab'), 'phonetic': '[${loc.translate('kebab_phrases')}]', 'type': 'word' },
    { 'id': '218', 'image': '', 'word': loc.translate('pelmeni'), 'phonetic': '[${loc.translate('pelmeni_phrases')}]', 'type': 'word' },
    { 'id': '219', 'image': '', 'word': loc.translate('biscuit'), 'phonetic': '[${loc.translate('biscuit_phrases')}]', 'type': 'word' },
    { 'id': '220', 'image': '', 'word': loc.translate('fresh'), 'phonetic': '[${loc.translate('fresh_phrases')}]', 'type': 'word' },
    { 'id': '221', 'image': '', 'word': loc.translate('fried_eggs'), 'phonetic': '[${loc.translate('fried_eggs_phrases')}]', 'type': 'word' },
    { 'id': '222', 'image': '', 'word': loc.translate('water'), 'phonetic': '[${loc.translate('water_phrases')}]', 'type': 'word' },
    { 'id': '223', 'image': '', 'word': loc.translate('coffee'), 'phonetic': '[${loc.translate('coffee_phrases')}]', 'type': 'word' },
    { 'id': '224', 'image': '', 'word': loc.translate('tea'), 'phonetic': '[${loc.translate('tea_phrases')}]', 'type': 'word' },
    { 'id': '225', 'image': '', 'word': loc.translate('sweet_tea'), 'phonetic': '[${loc.translate('sweet_tea_phrases')}]', 'type': 'word' },
    { 'id': '226', 'image': '', 'word': loc.translate('champagne'), 'phonetic': '[${loc.translate('champagne_phrases')}]', 'type': 'word' },
    { 'id': '227', 'image': '', 'word': loc.translate('fruit'), 'phonetic': '[${loc.translate('fruit_phrases')}]', 'type': 'word' },
    { 'id': '228', 'image': '', 'word': loc.translate('apple'), 'phonetic': '[${loc.translate('apple_phrases')}]', 'type': 'word' },
    { 'id': '229', 'image': '', 'word': loc.translate('pear'), 'phonetic': '[${loc.translate('pear_phrases')}]', 'type': 'word' },
    { 'id': '230', 'image': '', 'word': loc.translate('apricot'), 'phonetic': '[${loc.translate('apricot_phrases')}]', 'type': 'word' },
    { 'id': '231', 'image': '', 'word': loc.translate('peach'), 'phonetic': '[${loc.translate('peach_phrases')}]', 'type': 'word' },
    { 'id': '232', 'image': '', 'word': loc.translate('plum'), 'phonetic': '[${loc.translate('plum_phrases')}]', 'type': 'word' },
    { 'id': '233', 'image': '', 'word': loc.translate('cherry'), 'phonetic': '[${loc.translate('cherry_phrases')}]', 'type': 'word' },
    { 'id': '234', 'image': '', 'word': loc.translate('sour_cherry'), 'phonetic': '[${loc.translate('sour_cherry_phrases')}]', 'type': 'word' },
    { 'id': '235', 'image': '', 'word': loc.translate('grapes'), 'phonetic': '[${loc.translate('grapes_phrases')}]', 'type': 'word' },
    { 'id': '236', 'image': '', 'word': loc.translate('pomegranate'), 'phonetic': '[${loc.translate('pomegranate_phrases')}]', 'type': 'word' },
    { 'id': '237', 'image': '', 'word': loc.translate('fig'), 'phonetic': '[${loc.translate('fig_phrases')}]', 'type': 'word' },
    { 'id': '238', 'image': '', 'word': loc.translate('melon'), 'phonetic': '[${loc.translate('melon_phrases')}]', 'type': 'word' },
    { 'id': '239', 'image': '', 'word': loc.translate('watermelon'), 'phonetic': '[${loc.translate('watermelon_phrases')}]', 'type': 'word' },
    { 'id': '240', 'image': '', 'word': loc.translate('lemon'), 'phonetic': '[${loc.translate('lemon_phrases')}]', 'type': 'word' },
    { 'id': '241', 'image': '', 'word': loc.translate('mandarin_tangerine'), 'phonetic': '[${loc.translate('mandarin_tangerine_phrases')}]', 'type': 'word' },
    { 'id': '242', 'image': '', 'word': loc.translate('banana'), 'phonetic': '[${loc.translate('banana_phrases')}]', 'type': 'word' },
    { 'id': '243', 'image': '', 'word': loc.translate('berry'), 'phonetic': '[${loc.translate('berry_phrases')}]', 'type': 'word' },
    { 'id': '244', 'image': '', 'word': loc.translate('strawberry'), 'phonetic': '[${loc.translate('strawberry_phrases')}]', 'type': 'word' },
    { 'id': '245', 'image': '', 'word': loc.translate('raspberry'), 'phonetic': '[${loc.translate('raspberry_phrases')}]', 'type': 'word' },

  ];
}
