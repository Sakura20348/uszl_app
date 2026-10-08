import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

// =======================================================================
// FOOD LESSONS
// =======================================================================
class FoodLessonsData {
  final BuildContext context; FoodLessonsData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get item => [
    {
      'id': 'eat_0', 'count': 5, 'image': '', // food
      'imageTime': 'web/icons/time.png', 'imageHand': 'web/icons/hand.png', 'titleKey': '${loc.translate('food')} ${loc.translate('words')}', 'time': '5 ${loc.translate('time_min')}', 'click': '10 ${loc.translate('hints')}'
    },
    {
      'id': 'eat_1', 'count': 10, 'image': '', // steamed_dumplings and tea
      'imageTime': 'web/icons/time.png', 'imageHand': 'web/icons/hand.png', 'titleKey': '${loc.translate('steamed_dumplings')} - ${loc.translate('tea')} ${loc.translate('words')}', 'time': '5 ${loc.translate('time_min')}', 'click': '10 ${loc.translate('hints')}'
    },
    {
      'id': 'eat_2', 'count': 10, 'image': '', // sweet_tea and tender_food
      'imageTime': 'web/icons/time.png', 'imageHand': 'web/icons/hand.png', 'titleKey': '${loc.translate('sweet_tea')} - ${loc.translate('tender_food')} ${loc.translate('words')}', 'time': '5 ${loc.translate('time_min')}', 'click': '10 ${loc.translate('hints')}'
    },
    {
      'id': 'eat_3', 'count': 10, 'image': '', // fruit and pomegranate
      'imageTime': 'web/icons/time.png', 'imageHand': 'web/icons/hand.png', 'titleKey': '${loc.translate('fruit')} - ${loc.translate('pomegranate')} ${loc.translate('words')}', 'time': '5 ${loc.translate('time_min')}', 'click': '10 ${loc.translate('hints')}'
    },
    {
      'id': 'eat_4', 'count': 10, 'image': '', // fig and vegetables
      'imageTime': 'web/icons/time.png', 'imageHand': 'web/icons/hand.png', 'titleKey': '${loc.translate('fig')} - ${loc.translate('vegetables')} ${loc.translate('words')}', 'time': '5 ${loc.translate('time_min')}', 'click': '10 ${loc.translate('hints')}'
    },
    {
      'id': 'eat_5', 'count': 10, 'image': '', // onion and cabbage
      'imageTime': 'web/icons/time.png', 'imageHand': 'web/icons/hand.png', 'titleKey': '${loc.translate('onion')} - ${loc.translate('cabbage')} ${loc.translate('words')}', 'time': '5 ${loc.translate('time_min')}', 'click': '10 ${loc.translate('hints')}'
    },
    {
      'id': 'eat_6', 'count': 10, 'image': '', // beetroot and bread
      'imageTime': 'web/icons/time.png', 'imageHand': 'web/icons/hand.png', 'titleKey': '${loc.translate('beetroot')} - ${loc.translate('bread')} ${loc.translate('words')}', 'time': '5 ${loc.translate('time_min')}', 'click': '10 ${loc.translate('hints')}'
    },
    {
      'id': 'eat_7', 'count': 10, 'image': '', // salt and yoghurt
      'imageTime': 'web/icons/time.png', 'imageHand': 'web/icons/hand.png', 'titleKey': '${loc.translate('salt')} - ${loc.translate('yoghurt')} ${loc.translate('words')}', 'time': '5 ${loc.translate('time_min')}', 'click': '10 ${loc.translate('hints')}'
    },
    {
      'id': 'eat_8', 'count': 10, 'image': '', // kefir and pancakes
      'imageTime': 'web/icons/time.png', 'imageHand': 'web/icons/hand.png', 'titleKey': '${loc.translate('kefir')} - ${loc.translate('pancakes')} ${loc.translate('words')}', 'time': '5 ${loc.translate('time_min')}', 'click': '10 ${loc.translate('hints')}'
    }
  ];
  Map<String, List<Map<String, dynamic>>> get storesByFoodLessons => { '0': item };
}

class FoodAndSamosaData {
  final BuildContext context; FoodAndSamosaData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get item => [
    {
      'id': '0', 'video': '', // food
      'title': loc.translate('words_food_symbol'), 'title_sub': loc.translate('words_food_symbol_sub'),
    },
    {
      'id': '1', 'video': '', // soup
      'title': loc.translate('words_soup_symbol'), 'title_sub': loc.translate('words_soup_symbol_sub'),
    },
    {
      'id': '2', 'video': '', // pilaf
      'title': loc.translate('words_pilaf_symbol'), 'title_sub': loc.translate('words_pilaf_symbol_sub'),
    },
    {
      'id': '3', 'video': '', // rice_pilaf
      'title': loc.translate('words_rice_pilaf_symbol'), 'title_sub': loc.translate('words_rice_pilaf_symbol_sub'),
    },
    {
      'id': '4', 'video': '', // samosa
      'title': loc.translate('words_samosa_symbol'), 'title_sub': loc.translate('words_samosa_symbol_sub'),
    },
  ];
}

class SteamedDumplingsAndTeaData {
  final BuildContext context; SteamedDumplingsAndTeaData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get item => [
    {
      'id': '0', 'video': '', // steamed_dumplings
      'title': loc.translate('words_steamed_dumplings_symbol'), 'title_sub': loc.translate('words_steamed_dumplings_symbol_sub'),
    },
    {
      'id': '1', 'video': '', // dumplings
      'title': loc.translate('words_dumplings_symbol'), 'title_sub': loc.translate('words_dumplings_symbol_sub'),
    },
    {
      'id': '2', 'video': '', // kebab
      'title': loc.translate('words_kebab_symbol'), 'title_sub': loc.translate('words_kebab_symbol_sub'),
    },
    {
      'id': '3', 'video': '', // pelmeni
      'title': loc.translate('words_pelmeni_symbol'), 'title_sub': loc.translate('words_pelmeni_symbol_sub'),
    },
    {
      'id': '4', 'video': '', // biscuit
      'title': loc.translate('words_biscuit_symbol'), 'title_sub': loc.translate('words_biscuit_symbol_sub'),
    },
  ];
}

class SteamedDumplingsAndTea2Data {
  final BuildContext context; SteamedDumplingsAndTea2Data({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get item => [
    {
      'id': '0', 'video': '', // fresh
      'title': loc.translate('words_fresh_symbol'), 'title_sub': loc.translate('words_fresh_symbol_sub'),
    },
    {
      'id': '1', 'video': '', // fried_eggs
      'title': loc.translate('words_fried_eggs_symbol'), 'title_sub': loc.translate('words_fried_eggs_symbol_sub'),
    },
    {
      'id': '2', 'video': '', // water
      'title': loc.translate('words_water_symbol'), 'title_sub': loc.translate('words_water_symbol_sub'),
    },
    {
      'id': '3', 'video': '', // coffee
      'title': loc.translate('words_coffee_symbol'), 'title_sub': loc.translate('words_coffee_symbol_sub'),
    },
    {
      'id': '4', 'video': '', // tea
      'title': loc.translate('words_tea_symbol'), 'title_sub': loc.translate('words_tea_symbol_sub'),
    },
  ];
}

class SweetTeaAndTenderFoodData {
  final BuildContext context; SweetTeaAndTenderFoodData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get item => [
    {
      'id': '0', 'video': '', // sweet_tea
      'title': loc.translate('words_sweet_tea_symbol'), 'title_sub': loc.translate('words_sweet_tea_symbol_sub'),
    },
    {
      'id': '1', 'video': '', // champagne
      'title': loc.translate('words_champagne_symbol'), 'title_sub': loc.translate('words_champagne_symbol_sub'),
    },
    {
      'id': '2', 'video': '', // meat
      'title': loc.translate('words_meat_symbol'), 'title_sub': loc.translate('words_meat_symbol_sub'),
    },
    {
      'id': '3', 'video': '', // egg
      'title': loc.translate('words_egg_symbol'), 'title_sub': loc.translate('words_egg_symbol_sub'),
    },
    {
      'id': '4', 'video': '', // rissole
      'title': loc.translate('words_rissole_symbol'), 'title_sub': loc.translate('words_rissole_symbol_sub'),
    },
  ];
}

class SweetTeaAndTenderFood2Data {
  final BuildContext context; SweetTeaAndTenderFood2Data({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get item => [
    {
      'id': '0', 'video': '', // sausages
      'title': loc.translate('words_sausages_symbol'), 'title_sub': loc.translate('words_sausages_symbol_sub'),
    },
    {
      'id': '1', 'video': '', // herring
      'title': loc.translate('words_herring_symbol'), 'title_sub': loc.translate('words_herring_symbol_sub'),
    },
    {
      'id': '2', 'video': '', // cake
      'title': loc.translate('words_cake_symbol'), 'title_sub': loc.translate('words_cake_symbol_sub'),
    },
    {
      'id': '3', 'video': '', // canned_food
      'title': loc.translate('words_canned_food_symbol'), 'title_sub': loc.translate('words_canned_food_symbol_sub'),
    },
    {
      'id': '4', 'video': '', // tender_food
      'title': loc.translate('words_tender_food_symbol'), 'title_sub': loc.translate('words_tender_food_symbol_sub'),
    },
  ];
}

class FruitAndPomegranateData {
  final BuildContext context; FruitAndPomegranateData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get item => [
    {
      'id': '0', 'video': '', // fruit
      'title': loc.translate('words_fruit_symbol'), 'title_sub': loc.translate('words_fruit_symbol_sub'),
    },
    {
      'id': '1', 'video': '', // apple
      'title': loc.translate('words_apple_symbol'), 'title_sub': loc.translate('words_apple_symbol_sub'),
    },
    {
      'id': '2', 'video': '', // pear
      'title': loc.translate('words_pear_symbol'), 'title_sub': loc.translate('words_pear_symbol_sub'),
    },
    {
      'id': '3', 'video': '', // apricot
      'title': loc.translate('words_apricot_symbol'), 'title_sub': loc.translate('words_apricot_symbol_sub'),
    },
    {
      'id': '4', 'video': '', // peach
      'title': loc.translate('words_peach_symbol'), 'title_sub': loc.translate('words_peach_symbol_sub'),
    },
  ];
}

class FruitAndPomegranate2Data {
  final BuildContext context; FruitAndPomegranate2Data({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get item => [
    {
      'id': '0', 'video': '', // plum
      'title': loc.translate('words_plum_symbol'), 'title_sub': loc.translate('words_plum_symbol_sub'),
    },
    {
      'id': '1', 'video': '', // cherry
      'title': loc.translate('words_cherry_symbol'), 'title_sub': loc.translate('words_cherry_symbol_sub'),
    },
    {
      'id': '2', 'video': '', // sour_cherry
      'title': loc.translate('words_sour_cherry_symbol'), 'title_sub': loc.translate('words_sour_cherry_symbol_sub'),
    },
    {
      'id': '3', 'video': '', // grapes
      'title': loc.translate('words_grapes_symbol'), 'title_sub': loc.translate('words_grapes_symbol_sub'),
    },
    {
      'id': '4', 'video': '', // pomegranate
      'title': loc.translate('words_pomegranate_symbol'), 'title_sub': loc.translate('words_pomegranate_symbol_sub'),
    },
  ];
}

class FigAndVegetablesData {
  final BuildContext context; FigAndVegetablesData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get item => [
    {
      'id': '0', 'video': '', // fig
      'title': loc.translate('words_fig_symbol'), 'title_sub': loc.translate('words_fig_symbol_sub'),
    },
    {
      'id': '1', 'video': '', // melon
      'title': loc.translate('words_melon_symbol'), 'title_sub': loc.translate('words_melon_symbol_sub'),
    },
    {
      'id': '2', 'video': '', // watermelon
      'title': loc.translate('words_watermelon_symbol'), 'title_sub': loc.translate('words_watermelon_symbol_sub'),
    },
    {
      'id': '3', 'video': '', // lemon
      'title': loc.translate('words_lemon_symbol'), 'title_sub': loc.translate('words_lemon_symbol_sub'),
    },
    {
      'id': '4', 'video': '', // mandarin_tangerine
      'title': loc.translate('words_mandarin_tangerine_symbol'), 'title_sub': loc.translate('words_mandarin_tangerine_symbol_sub'),
    },
  ];
}

class FigAndVegetables2Data {
  final BuildContext context; FigAndVegetables2Data({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get item => [
    {
      'id': '0', 'video': '', // banana
      'title': loc.translate('words_banana_symbol'), 'title_sub': loc.translate('words_banana_symbol_sub'),
    },
    {
      'id': '1', 'video': '', // berry
      'title': loc.translate('words_berry_symbol'), 'title_sub': loc.translate('words_berry_symbol_sub'),
    },
    {
      'id': '2', 'video': '', // strawberry
      'title': loc.translate('words_strawberry_symbol'), 'title_sub': loc.translate('words_strawberry_symbol_sub'),
    },
    {
      'id': '3', 'video': '', // raspberry
      'title': loc.translate('words_raspberry_symbol'), 'title_sub': loc.translate('words_raspberry_symbol_sub'),
    },
    {
      'id': '4', 'video': '', // vegetables
      'title': loc.translate('words_vegetables_symbol'), 'title_sub': loc.translate('words_vegetables_symbol_sub'),
    },
  ];
}

class OnionAndCabbageData {
  final BuildContext context; OnionAndCabbageData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get item => [
    {
      'id': '0', 'video': '', // onion
      'title': loc.translate('words_onion_symbol'), 'title_sub': loc.translate('words_onion_symbol_sub'),
    },
    {
      'id': '1', 'video': '', // potato
      'title': loc.translate('words_potato_symbol'), 'title_sub': loc.translate('words_potato_symbol_sub'),
    },
    {
      'id': '2', 'video': '', // carrot
      'title': loc.translate('words_carrot_symbol'), 'title_sub': loc.translate('words_carrot_symbol_sub'),
    },
    {
      'id': '3', 'video': '', // tomato
      'title': loc.translate('words_tomato_symbol'), 'title_sub': loc.translate('words_tomato_symbol_sub'),
    },
    {
      'id': '4', 'video': '', // cucumber
      'title': loc.translate('words_cucumber_symbol'), 'title_sub': loc.translate('words_cucumber_symbol_sub'),
    },
  ];
}

class OnionAndCabbage2Data {
  final BuildContext context; OnionAndCabbage2Data({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get item => [
    {
      'id': '0', 'video': '', // garlic
      'title': loc.translate('words_garlic_symbol'), 'title_sub': loc.translate('words_garlic_symbol_sub'),
    },
    {
      'id': '1', 'video': '', // pepper
      'title': loc.translate('words_pepper_symbol'), 'title_sub': loc.translate('words_pepper_symbol_sub'),
    },
    {
      'id': '2', 'video': '', // eggplant_aubergine
      'title': loc.translate('words_eggplant_aubergine_symbol'), 'title_sub': loc.translate('words_eggplant_aubergine_symbol_sub'),
    },
    {
      'id': '3', 'video': '', // pumpkin
      'title': loc.translate('words_pumpkin_symbol'), 'title_sub': loc.translate('words_pumpkin_symbol_sub'),
    },
    {
      'id': '4', 'video': '', // cabbage
      'title': loc.translate('words_cabbage_symbol'), 'title_sub': loc.translate('words_cabbage_symbol_sub'),
    },
  ];
}

class BeetrootAndBreadData {
  final BuildContext context; BeetrootAndBreadData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get item => [
    {
      'id': '0', 'video': '', // beetroot
      'title': loc.translate('words_beetroot_symbol'), 'title_sub': loc.translate('words_beetroot_symbol_sub'),
    },
    {
      'id': '1', 'video': '', // small_red_radish
      'title': loc.translate('words_small_red_radish_symbol'), 'title_sub': loc.translate('words_small_red_radish_symbol_sub'),
    },
    {
      'id': '2', 'video': '', // black_radish
      'title': loc.translate('words_black_radish_symbol'), 'title_sub': loc.translate('words_black_radish_symbol_sub'),
    },
    {
      'id': '3', 'video': '', // corn/maize
      'title': loc.translate('words_corn/maize_symbol'), 'title_sub': loc.translate('words_corn/maize_symbol_sub'),
    },
    {
      'id': '4', 'video': '', // mushroom
      'title': loc.translate('words_mushroom_symbol'), 'title_sub': loc.translate('words_mushroom_symbol_sub'),
    },
  ];
}

class BeetrootAndBread2Data {
  final BuildContext context; BeetrootAndBread2Data({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get item => [
    {
      'id': '0', 'video': '', // cereal
      'title': loc.translate('words_cereal_symbol'), 'title_sub': loc.translate('words_cereal_symbol_sub'),
    },
    {
      'id': '1', 'video': '', // buckwheat
      'title': loc.translate('words_buckwheat_symbol'), 'title_sub': loc.translate('words_buckwheat_symbol_sub'),
    },
    {
      'id': '2', 'video': '', // millet
      'title': loc.translate('words_millet_symbol'), 'title_sub': loc.translate('words_millet_symbol_sub'),
    },
    {
      'id': '3', 'video': '', // semolina
      'title': loc.translate('words_semolina_symbol'), 'title_sub': loc.translate('words_semolina_symbol_sub'),
    },
    {
      'id': '4', 'video': '', // bread
      'title': loc.translate('words_bread_symbol'), 'title_sub': loc.translate('words_bread_symbol_sub'),
    },
  ];
}

class SaltAndYoghurtData {
  final BuildContext context; SaltAndYoghurtData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get item => [
    {
      'id': '0', 'video': '', // salt
      'title': loc.translate('words_salt_symbol'), 'title_sub': loc.translate('words_salt_symbol_sub'),
    },
    {
      'id': '1', 'video': '', // sugar
      'title': loc.translate('words_sugar_symbol'), 'title_sub': loc.translate('words_sugar_symbol_sub'),
    },
    {
      'id': '2', 'video': '', // flour
      'title': loc.translate('words_flour_symbol'), 'title_sub': loc.translate('words_flour_symbol_sub'),
    },
    {
      'id': '3', 'video': '', // nut
      'title': loc.translate('words_nut_symbol'), 'title_sub': loc.translate('words_nut_symbol_sub'),
    },
    {
      'id': '4', 'video': '', // seeds
      'title': loc.translate('words_seeds_symbol'), 'title_sub': loc.translate('words_seeds_symbol_sub'),
    },
  ];
}

class SaltAndYoghurt2Data {
  final BuildContext context; SaltAndYoghurt2Data({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get item => [
    {
      'id': '0', 'video': '', // groats
      'title': loc.translate('words_groats_symbol'), 'title_sub': loc.translate('words_groats_symbol_sub'),
    },
    {
      'id': '1', 'video': '', // porridge
      'title': loc.translate('words_porridge_symbol'), 'title_sub': loc.translate('words_porridge_symbol_sub'),
    },
    {
      'id': '2', 'video': '', // macaroni
      'title': loc.translate('words_macaroni_symbol'), 'title_sub': loc.translate('words_macaroni_symbol_sub'),
    },
    {
      'id': '3', 'video': '', // dough
      'title': loc.translate('words_dough_symbol'), 'title_sub': loc.translate('words_dough_symbol_sub'),
    },
    {
      'id': '4', 'video': '', // yoghurt
      'title': loc.translate('words_yoghurt_symbol'), 'title_sub': loc.translate('words_yoghurt_symbol_sub'),
    },
  ];
}

class KefirAndPancakesData {
  final BuildContext context; KefirAndPancakesData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get item => [
    {
      'id': '0', 'video': '', // kefir
      'title': loc.translate('words_kefir_symbol'), 'title_sub': loc.translate('words_kefir_symbol_sub'),
    },
    {
      'id': '1', 'video': '', // cottage_cheese
      'title': loc.translate('words_cottage_cheese_symbol'), 'title_sub': loc.translate('words_cottage_cheese_symbol_sub'),
    },
    {
      'id': '2', 'video': '', // butter
      'title': loc.translate('words_butter_symbol'), 'title_sub': loc.translate('words_butter_symbol_sub'),
    },
    {
      'id': '3', 'video': '', // milk
      'title': loc.translate('words_milk_symbol'), 'title_sub': loc.translate('words_milk_symbol_sub'),
    },
    {
      'id': '4', 'video': '', // cheese
      'title': loc.translate('words_cheese_symbol'), 'title_sub': loc.translate('words_cheese_symbol_sub'),
    },
  ];
}

class KefirAndPancakes2Data {
  final BuildContext context; KefirAndPancakes2Data({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get item => [
    {
      'id': '0', 'video': '', // sour_cream
      'title': loc.translate('words_sour_cream_symbol'), 'title_sub': loc.translate('words_sour_cream_symbol_sub'),
    },
    {
      'id': '1', 'video': '', // oil
      'title': loc.translate('words_oil_symbol'), 'title_sub': loc.translate('words_oil_symbol_sub'),
    },
    {
      'id': '2', 'video': '', // vegetable_oil
      'title': loc.translate('words_vegetable_oil_symbol'), 'title_sub': loc.translate('words_vegetable_oil_symbol_sub'),
    },
    {
      'id': '3', 'video': '', // ice_cream
      'title': loc.translate('words_ice_cream_symbol'), 'title_sub': loc.translate('words_ice_cream_symbol_sub'),
    },
    {
      'id': '4', 'video': '', // pancakes
      'title': loc.translate('words_pancakes_symbol'), 'title_sub': loc.translate('words_pancakes_symbol_sub'),
    },
  ];
}

// =======================================================================
// WORDS
// =======================================================================
class Food1Data {
  final BuildContext context; Food1Data({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get item => [
    { 'image': '', 'label': loc.translate('rice_pilaf') }, { 'image': '', 'label': loc.translate('samosa') },
    { 'image': '', 'label': loc.translate('soup') }, { 'image': '', 'label': loc.translate('pilaf') },
  ];
  Map<String, List<Map<String, dynamic>>> get storeFood => { '0': item };
}

class Food2Data {
  final BuildContext context; Food2Data({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get item => [
    { 'image': '', 'label': loc.translate('pelmeni') }, { 'image': '', 'label': loc.translate('kebab') },
    { 'image': '', 'label': loc.translate('biscuit') }, { 'image': '', 'label': loc.translate('steamed_dumplings') },
  ];
  Map<String, List<Map<String, dynamic>>> get storeFood => { '0': item };
}

class Food3Data {
  final BuildContext context; Food3Data({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get item => [
    { 'image': '', 'label': loc.translate('tea') }, { 'image': '', 'label': loc.translate('water') },
    { 'image': '', 'label': loc.translate('fresh') }, { 'image': '', 'label': loc.translate('fried_eggs') },
  ];
  Map<String, List<Map<String, dynamic>>> get storeFood => { '0': item };
}

class Food4Data {
  final BuildContext context; Food4Data({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get item => [
    { 'image': '', 'label': loc.translate('rissole') }, { 'image': '', 'label': loc.translate('sweet_tea') },
    { 'image': '', 'label': loc.translate('meat') }, { 'image': '', 'label': loc.translate('egg') },
  ];
  Map<String, List<Map<String, dynamic>>> get storeFood => { '0': item };
}

class Food5Data {
  final BuildContext context; Food5Data({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get item => [
    { 'image': '', 'label': loc.translate('tender_food') }, { 'image': '', 'label': loc.translate('herring') },
    { 'image': '', 'label': loc.translate('sausages') }, { 'image': '', 'label': loc.translate('canned_food') },
  ];
  Map<String, List<Map<String, dynamic>>> get storeFood => { '0': item };
}

class Food6Data {
  final BuildContext context; Food6Data({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get item => [
    { 'image': '', 'label': loc.translate('peach') }, { 'image': '', 'label': loc.translate('fruit') },
    { 'image': '', 'label': loc.translate('pear') }, { 'image': '', 'label': loc.translate('apricot') },
  ];
  Map<String, List<Map<String, dynamic>>> get storeFood => { '0': item };
}

class Food7Data {
  final BuildContext context; Food7Data({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get item => [
    { 'image': '', 'label': loc.translate('cherry') }, { 'image': '', 'label': loc.translate('pomegranate') },
    { 'image': '', 'label': loc.translate('grapes') }, { 'image': '', 'label': loc.translate('sour_cherry') },
  ];
  Map<String, List<Map<String, dynamic>>> get storeFood => { '0': item };
}

class Food8Data {
  final BuildContext context; Food8Data({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get item => [
    { 'image': '', 'label': loc.translate('cherry') }, { 'image': '', 'label': loc.translate('pomegranate') },
    { 'image': '', 'label': loc.translate('grapes') }, { 'image': '', 'label': loc.translate('sour_cherry') },
  ];
  Map<String, List<Map<String, dynamic>>> get storeFood => { '0': item };
}

class Food9Data {
  final BuildContext context; Food9Data({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get item => [
    { 'image': '', 'label': loc.translate('melon') }, { 'image': '', 'label': loc.translate('fig') },
    { 'image': '', 'label': loc.translate('lemon') }, { 'image': '', 'label': loc.translate('mandarin_tangerine') },
  ];
  Map<String, List<Map<String, dynamic>>> get storeFood => { '0': item };
}

class Food10Data {
  final BuildContext context; Food10Data({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get item => [
    { 'image': '', 'label': loc.translate('banana') }, { 'image': '', 'label': loc.translate('berry') },
    { 'image': '', 'label': loc.translate('vegetables') }, { 'image': '', 'label': loc.translate('strawberry') },
  ];
  Map<String, List<Map<String, dynamic>>> get storeFood => { '0': item };
}

class Food1Data1 {
  final BuildContext context; Food1Data1({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get item => [
    { 'image': '', 'label': loc.translate('cucumber') }, { 'image': '', 'label': loc.translate('potato') },
    { 'image': '', 'label': loc.translate('tomato') }, { 'image': '', 'label': loc.translate('onion') },
  ];
  Map<String, List<Map<String, dynamic>>> get storeFood => { '0': item };
}

class Food1Data2 {
  final BuildContext context; Food1Data2({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get item => [
    { 'image': '', 'label': loc.translate('cabbage') }, { 'image': '', 'label': loc.translate('garlic') },
    { 'image': '', 'label': loc.translate('eggplant_aubergine') }, { 'image': '', 'label': loc.translate('pepper') },
  ];
  Map<String, List<Map<String, dynamic>>> get storeFood => { '0': item };
}

class Food1Data3 {
  final BuildContext context; Food1Data3({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get item => [
    { 'image': '', 'label': loc.translate('mushroom') }, { 'image': '', 'label': loc.translate('black_radish') },
    { 'image': '', 'label': loc.translate('beetroot') }, { 'image': '', 'label': loc.translate('corn/maize') },
  ];
  Map<String, List<Map<String, dynamic>>> get storeFood => { '0': item };
}

class Food1Data4 {
  final BuildContext context; Food1Data4({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get item => [
    { 'image': '', 'label': loc.translate('millet') }, { 'image': '', 'label': loc.translate('semolina') },
    { 'image': '', 'label': loc.translate('bread') }, { 'image': '', 'label': loc.translate('buckwheat') },
  ];
  Map<String, List<Map<String, dynamic>>> get storeFood => { '0': item };
}

class Food1Data5 {
  final BuildContext context; Food1Data5({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get item => [
    { 'image': '', 'label': loc.translate('nut') }, { 'image': '', 'label': loc.translate('seeds') },
    { 'image': '', 'label': loc.translate('flour') }, { 'image': '', 'label': loc.translate('salt') },
  ];
  Map<String, List<Map<String, dynamic>>> get storeFood => { '0': item };
}

class Food1Data6 {
  final BuildContext context; Food1Data6({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get item => [
    { 'image': '', 'label': loc.translate('dough') }, { 'image': '', 'label': loc.translate('porridge') },
    { 'image': '', 'label': loc.translate('macaroni') }, { 'image': '', 'label': loc.translate('yoghurt') },
  ];
  Map<String, List<Map<String, dynamic>>> get storeFood => { '0': item };
}

class Food1Data7 {
  final BuildContext context; Food1Data7({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get item => [
    { 'image': '', 'label': loc.translate('cheese') }, { 'image': '', 'label': loc.translate('kefir') },
    { 'image': '', 'label': loc.translate('butter') }, { 'image': '', 'label': loc.translate('milk') },
  ];
  Map<String, List<Map<String, dynamic>>> get storeFood => { '0': item };
}

class Food1Data8 {
  final BuildContext context; Food1Data8({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get item => [
    { 'image': '', 'label': loc.translate('ice_cream') }, { 'image': '', 'label': loc.translate('sour_cream') },
    { 'image': '', 'label': loc.translate('pancakes') }, { 'image': '', 'label': loc.translate('oil') },
  ];
  Map<String, List<Map<String, dynamic>>> get storeFood => { '0': item };
}

class ExamFood1Data {
  final BuildContext context; ExamFood1Data({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get item => [
    { 'id': '0', 'image': '' },// samosa
    { 'id': '1', 'image': '' },// rice_pilaf
    { 'id': '2', 'image': '' },// food
    { 'id': '3', 'image': '' },// soup
  ];
  Map<String, List<Map<String, dynamic>>> get storeExamWords => { '0': item };
}

class ExamFood2Data {
  final BuildContext context; ExamFood2Data({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get item => [
    { 'id': '0', 'image': '' },// biscuit
    { 'id': '1', 'image': '' },// water
    { 'id': '2', 'image': '' },// tea
    { 'id': '3', 'image': '' },// fried_eggs
  ];
  Map<String, List<Map<String, dynamic>>> get storeExamWords => { '0': item };
}

class ExamFood3Data {
  final BuildContext context; ExamFood3Data({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get item => [
    { 'id': '0', 'image': '' },// canned_food
    { 'id': '1', 'image': '' },// meat
    { 'id': '2', 'image': '' },// sausages
    { 'id': '3', 'image': '' },// tender_food
  ];
  Map<String, List<Map<String, dynamic>>> get storeExamWords => { '0': item };
}

class ExamFood4Data {
  final BuildContext context; ExamFood4Data({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get item => [
    { 'id': '0', 'image': '' },// peach
    { 'id': '1', 'image': '' },// apple
    { 'id': '2', 'image': '' },// pomegranate
    { 'id': '3', 'image': '' },// plum
  ];
  Map<String, List<Map<String, dynamic>>> get storeExamWords => { '0': item };
}

class ExamFood5Data {
  final BuildContext context; ExamFood5Data({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get item => [
    { 'id': '0', 'image': '' },// watermelon
    { 'id': '1', 'image': '' },// raspberry
    { 'id': '2', 'image': '' },// fig
    { 'id': '3', 'image': '' },// lemon
  ];
  Map<String, List<Map<String, dynamic>>> get storeExamWords => { '0': item };
}

class ExamFood6Data {
  final BuildContext context; ExamFood6Data({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get item => [
    { 'id': '0', 'image': '' },// cucumber
    { 'id': '1', 'image': '' },// pumpkin
    { 'id': '2', 'image': '' },// onion
    { 'id': '3', 'image': '' },// pepper
  ];
  Map<String, List<Map<String, dynamic>>> get storeExamWords => { '0': item };
}

class ExamFood7Data {
  final BuildContext context; ExamFood7Data({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get item => [
    { 'id': '0', 'image': '' },// cereal
    { 'id': '1', 'image': '' },// corn/maize
    { 'id': '2', 'image': '' },// small_red_radish
    { 'id': '3', 'image': '' },// semolina
  ];
  Map<String, List<Map<String, dynamic>>> get storeExamWords => { '0': item };
}

class ExamFood8Data {
  final BuildContext context; ExamFood8Data({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get item => [
    { 'id': '0', 'image': '' },// yoghurt
    { 'id': '1', 'image': '' },// seeds
    { 'id': '2', 'image': '' },// flour
    { 'id': '3', 'image': '' },// macaroni
  ];
  Map<String, List<Map<String, dynamic>>> get storeExamWords => { '0': item };
}

class ExamFood9Data {
  final BuildContext context; ExamFood9Data({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get item => [
    { 'id': '0', 'image': '' },// sour_cream
    { 'id': '1', 'image': '' },// cheese
    { 'id': '2', 'image': '' },// milk
    { 'id': '3', 'image': '' },// pancakes
  ];
  Map<String, List<Map<String, dynamic>>> get storeExamWords => { '0': item };
}

// =======================================================================
// FEELINGS LESSONS
// =======================================================================
class FeelingsLessonsData {
  final BuildContext context; FeelingsLessonsData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get item => [
    {
      'id': 'feel_0', 'count': 10, 'image': '', // feelings and coarse
      'imageTime': 'web/icons/time.png', 'imageHand': 'web/icons/hand.png', 'titleKey': '${loc.translate('feelings')} - ${loc.translate('coarse')} ${loc.translate('words')}', 'time': '5 ${loc.translate('time_min')}', 'click': '10 ${loc.translate('hints')}'
    },
    {
      'id': 'feel_1', 'count': 10, 'image': '', // sad and arrogant
      'imageTime': 'web/icons/time.png', 'imageHand': 'web/icons/hand.png', 'titleKey': '${loc.translate('sad')} - ${loc.translate('arrogant')} ${loc.translate('words')}', 'time': '5 ${loc.translate('time_min')}', 'click': '10 ${loc.translate('hints')}'
    },
    {
      'id': 'feel_2', 'count': 10, 'image': '', // wicked and like
      'imageTime': 'web/icons/time.png', 'imageHand': 'web/icons/hand.png', 'titleKey': '${loc.translate('wicked')} - ${loc.translate('like')} ${loc.translate('words')}', 'time': '5 ${loc.translate('time_min')}', 'click': '10 ${loc.translate('hints')}'
    },
    {
      'id': 'feel_3', 'count': 10, 'image': '', // love and scare
      'imageTime': 'web/icons/time.png', 'imageHand': 'web/icons/hand.png', 'titleKey': '${loc.translate('love')} - ${loc.translate('scare')} ${loc.translate('words')}', 'time': '5 ${loc.translate('time_min')}', 'click': '10 ${loc.translate('hints')}'
    },
    {
      'id': 'feel_4', 'count': 10, 'image': '', // be_scared and laugh
      'imageTime': 'web/icons/time.png', 'imageHand': 'web/icons/hand.png', 'titleKey': '${loc.translate('be_scared')} - ${loc.translate('laugh')} ${loc.translate('words')}', 'time': '5 ${loc.translate('time_min')}', 'click': '10 ${loc.translate('hints')}'
    },
    {
      'id': 'feel_5', 'count': 10, 'image': '', // assiduous and smile
      'imageTime': 'web/icons/time.png', 'imageHand': 'web/icons/hand.png', 'titleKey': '${loc.translate('assiduous')} - ${loc.translate('smile')} ${loc.translate('words')}', 'time': '5 ${loc.translate('time_min')}', 'click': '10 ${loc.translate('hints')}'
    },
    {
      'id': 'feel_6', 'count': 11, 'image': '', // tired and emotions
      'imageTime': 'web/icons/time.png', 'imageHand': 'web/icons/hand.png', 'titleKey': '${loc.translate('tired')} - ${loc.translate('emotions')} ${loc.translate('words')}', 'time': '5 ${loc.translate('time_min')}', 'click': '10 ${loc.translate('hints')}'
    }
  ];
  Map<String, List<Map<String, dynamic>>> get storesByFeelingsLessons => { '0': item };
}

class FeelingsAndCoarseData {
  final BuildContext context; FeelingsAndCoarseData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get item => [
    {
      'id': '0', 'video': '', // feelings
      'title': loc.translate('words_feelings_symbol'), 'title_sub': loc.translate('words_feelings_symbol_sub'),
    },
    {
      'id': '1', 'video': '', // pain
      'title': loc.translate('words_pain_symbol'), 'title_sub': loc.translate('words_pain_symbol_sub'),
    },
    {
      'id': '2', 'video': '', // afraid
      'title': loc.translate('words_afraid_symbol'), 'title_sub': loc.translate('words_afraid_symbol_sub'),
    },
    {
      'id': '3', 'video': '', // courteous
      'title': loc.translate('words_courteous_symbol'), 'title_sub': loc.translate('words_courteous_symbol_sub'),
    },
    {
      'id': '4', 'video': '', // cheerful
      'title': loc.translate('words_cheerful_symbol'), 'title_sub': loc.translate('words_cheerful_symbol_sub'),
    },
  ];
}

class FeelingsAndCoarse2Data {
  final BuildContext context; FeelingsAndCoarse2Data({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get item => [
    {
      'id': '0', 'video': '', // agitated
      'title': loc.translate('words_agitated_symbol'), 'title_sub': loc.translate('words_agitated_symbol_sub'),
    },
    {
      'id': '1', 'video': '', // amorousness
      'title': loc.translate('words_amorousness_symbol'), 'title_sub': loc.translate('words_amorousness_symbol_sub'),
    },
    {
      'id': '2', 'video': '', // proud
      'title': loc.translate('words_proud_symbol'), 'title_sub': loc.translate('words_proud_symbol_sub'),
    },
    {
      'id': '3', 'video': '', // fervent
      'title': loc.translate('words_fervent_symbol'), 'title_sub': loc.translate('words_fervent_symbol_sub'),
    },
    {
      'id': '4', 'video': '', // coarse
      'title': loc.translate('words_coarse_symbol'), 'title_sub': loc.translate('words_coarse_symbol_sub'),
    },
  ];
}
// =======================================================================
// WORDS
// =======================================================================
class Feelings1Data {
  final BuildContext context; Feelings1Data({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get item => [
    { 'image': '', 'label': loc.translate('feelings') }, { 'image': '', 'label': loc.translate('pain') },
    { 'image': '', 'label': loc.translate('cheerful') }, { 'image': '', 'label': loc.translate('courteous') },
  ];
  Map<String, List<Map<String, dynamic>>> get storeFeelings => { '0': item };
}

class Feelings2Data {
  final BuildContext context; Feelings2Data({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get item => [
    { 'image': '', 'label': loc.translate('coarse') }, { 'image': '', 'label': loc.translate('proud') },
    { 'image': '', 'label': loc.translate('amorousness') }, { 'image': '', 'label': loc.translate('agitated') },
  ];
  Map<String, List<Map<String, dynamic>>> get storeFeelings => { '0': item };
}

class ExamFeelings1Data {
  final BuildContext context; ExamFeelings1Data({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get item => [
    { 'id': '0', 'image': '' },// pain
    { 'id': '1', 'image': '' },// courteous
    { 'id': '2', 'image': '' },// proud
    { 'id': '3', 'image': '' },// coarse
  ];
  Map<String, List<Map<String, dynamic>>> get storeExamFeel => { '0': item };
}