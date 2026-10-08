import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

class FoodData {
  final BuildContext context; FoodData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late List<Map<String, dynamic>> foodItem = [
    { 'id': '0', 'image': '', 'title': loc.translate('food'), 'title_sub': loc.translate('food_phrases') },
    { 'id': '1', 'image': '', 'title': loc.translate('soup'), 'title_sub': loc.translate('soup_phrases') },
    { 'id': '2', 'image': '', 'title': loc.translate('pilaf'), 'title_sub': loc.translate('pilaf_phrases') },
    { 'id': '3', 'image': '', 'title': loc.translate('rice_pilaf'), 'title_sub': loc.translate('rice_pilaf_phrases') },
    { 'id': '4', 'image': '', 'title': loc.translate('samosa'), 'title_sub': loc.translate('samosa_phrases') },
    { 'id': '5', 'image': '', 'title': loc.translate('steamed_dumplings'), 'title_sub': loc.translate('steamed_dumplings_phrases') },
    { 'id': '6', 'image': '', 'title': loc.translate('dumplings'), 'title_sub': loc.translate('dumplings_phrases') },
    { 'id': '7', 'image': '', 'title': loc.translate('kebab'), 'title_sub': loc.translate('kebab_phrases') },
    { 'id': '8', 'image': '', 'title': loc.translate('pelmeni'), 'title_sub': loc.translate('pelmeni_phrases') },
    { 'id': '9', 'image': '', 'title': loc.translate('biscuit'), 'title_sub': loc.translate('biscuit_phrases') },
    { 'id': '10', 'image': '', 'title': loc.translate('fresh'), 'title_sub': loc.translate('fresh_phrases') },
    { 'id': '11', 'image': '', 'title': loc.translate('fried_eggs'), 'title_sub': loc.translate('fried_eggs_phrases') },
    { 'id': '12', 'image': '', 'title': loc.translate('water'), 'title_sub': loc.translate('water_phrases') },
    { 'id': '13', 'image': '', 'title': loc.translate('coffee'), 'title_sub': loc.translate('coffee_phrases') },
    { 'id': '14', 'image': '', 'title': loc.translate('tea'), 'title_sub': loc.translate('tea_phrases') },
    { 'id': '15', 'image': '', 'title': loc.translate('sweet_tea'), 'title_sub': loc.translate('sweet_tea_phrases') },
    { 'id': '16', 'image': '', 'title': loc.translate('champagne'), 'title_sub': loc.translate('champagne_phrases') },
    { 'id': '17', 'image': '', 'title': loc.translate('meat'), 'title_sub': loc.translate('meat_phrases') },
    { 'id': '18', 'image': '', 'title': loc.translate('egg'), 'title_sub': loc.translate('egg_phrases') },
    { 'id': '19', 'image': '', 'title': loc.translate('rissole'), 'title_sub': loc.translate('rissole_phrases') },
    { 'id': '20', 'image': '', 'title': loc.translate('sausages'), 'title_sub': loc.translate('sausages_phrases') },
    { 'id': '21', 'image': '', 'title': loc.translate('herring'), 'title_sub': loc.translate('herring_phrases') },
    { 'id': '22', 'image': '', 'title': loc.translate('cake'), 'title_sub': loc.translate('cake_phrases') },
    { 'id': '23', 'image': '', 'title': loc.translate('canned_food'), 'title_sub': loc.translate('canned_food_phrases') },
    { 'id': '24', 'image': '', 'title': loc.translate('tender_food'), 'title_sub': loc.translate('tender_food_phrases') },
  ];
}

class FruitsData {
  final BuildContext context; FruitsData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late List<Map<String, dynamic>> fruitsItem = [
    { 'id': '0', 'image': '', 'title': loc.translate('fruit'), 'title_sub': loc.translate('fruit_phrases') },
    { 'id': '1', 'image': '', 'title': loc.translate('apple'), 'title_sub': loc.translate('apple_phrases') },
    { 'id': '2', 'image': '', 'title': loc.translate('pear'), 'title_sub': loc.translate('pear_phrases') },
    { 'id': '3', 'image': '', 'title': loc.translate('apricot'), 'title_sub': loc.translate('apricot_phrases') },
    { 'id': '4', 'image': '', 'title': loc.translate('peach'), 'title_sub': loc.translate('peach_phrases') },
    { 'id': '5', 'image': '', 'title': loc.translate('plum'), 'title_sub': loc.translate('plum_phrases') },
    { 'id': '6', 'image': '', 'title': loc.translate('cherry'), 'title_sub': loc.translate('cherry_phrases') },
    { 'id': '7', 'image': '', 'title': loc.translate('sour_cherry'), 'title_sub': loc.translate('sour_cherry_phrases') },
    { 'id': '8', 'image': '', 'title': loc.translate('grapes'), 'title_sub': loc.translate('grapes_phrases') },
    { 'id': '9', 'image': '', 'title': loc.translate('pomegranate'), 'title_sub': loc.translate('pomegranate_phrases') },
    { 'id': '10', 'image': '', 'title': loc.translate('fig'), 'title_sub': loc.translate('fig_phrases') },
    { 'id': '11', 'image': '', 'title': loc.translate('melon'), 'title_sub': loc.translate('melon_phrases') },
    { 'id': '12', 'image': '', 'title': loc.translate('watermelon'), 'title_sub': loc.translate('watermelon_phrases') },
    { 'id': '13', 'image': '', 'title': loc.translate('lemon'), 'title_sub': loc.translate('lemon_phrases') },
    { 'id': '14', 'image': '', 'title': loc.translate('mandarin_tangerine'), 'title_sub': loc.translate('mandarin_tangerine_phrases') },
    { 'id': '15', 'image': '', 'title': loc.translate('banana'), 'title_sub': loc.translate('banana_phrases') },
    { 'id': '16', 'image': '', 'title': loc.translate('berry'), 'title_sub': loc.translate('berry_phrases') },
    { 'id': '17', 'image': '', 'title': loc.translate('strawberry'), 'title_sub': loc.translate('strawberry_phrases') },
    { 'id': '18', 'image': '', 'title': loc.translate('raspberry'), 'title_sub': loc.translate('raspberry_phrases') },
  ];
}

class VegetablesData {
  final BuildContext context; VegetablesData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late List<Map<String, dynamic>> vegetablesItem = [
    { 'id': '0', 'image': '', 'title': loc.translate('vegetables'), 'title_sub': loc.translate('vegetables_phrases') },

    { 'id': '1', 'image': '', 'title': loc.translate('onion'), 'title_sub': loc.translate('onion_phrases') },
    { 'id': '2', 'image': '', 'title': loc.translate('potato'), 'title_sub': loc.translate('potato_phrases') },
    { 'id': '3', 'image': '', 'title': loc.translate('carrot'), 'title_sub': loc.translate('carrot_phrases') },
    { 'id': '4', 'image': '', 'title': loc.translate('tomato'), 'title_sub': loc.translate('tomato_phrases') },
    { 'id': '5', 'image': '', 'title': loc.translate('cucumber'), 'title_sub': loc.translate('cucumber_phrases') },
    { 'id': '6', 'image': '', 'title': loc.translate('garlic'), 'title_sub': loc.translate('garlic_phrases') },
    { 'id': '7', 'image': '', 'title': loc.translate('pepper'), 'title_sub': loc.translate('pepper_phrases') },
    { 'id': '8', 'image': '', 'title': loc.translate('eggplant_aubergine'), 'title_sub': loc.translate('eggplant_aubergine_phrases') },
    { 'id': '9', 'image': '', 'title': loc.translate('pumpkin'), 'title_sub': loc.translate('pumpkin_phrases') },
    { 'id': '10', 'image': '', 'title': loc.translate('cabbage'), 'title_sub': loc.translate('cabbage_phrases') },
    { 'id': '11', 'image': '', 'title': loc.translate('beetroot'), 'title_sub': loc.translate('beetroot_phrases') },
    { 'id': '12', 'image': '', 'title': loc.translate('small_red_radish'), 'title_sub': loc.translate('small_red_radish_phrases') },
    { 'id': '13', 'image': '', 'title': loc.translate('black_radish'), 'title_sub': loc.translate('black_radish_phrases') },
    { 'id': '14', 'image': '', 'title': loc.translate('corn/maize'), 'title_sub': loc.translate('corn/maize_phrases') },
    { 'id': '15', 'image': '', 'title': loc.translate('mushroom'), 'title_sub': loc.translate('mushroom_phrases') },
  ];
}

class CerealsData {
  final BuildContext context; CerealsData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late List<Map<String, dynamic>> cerealsItem = [
    { 'id': '0', 'image': '', 'title': loc.translate('cereal'), 'title_sub': loc.translate('cereal_phrases') },
    { 'id': '1', 'image': '', 'title': loc.translate('buckwheat'), 'title_sub': loc.translate('buckwheat_phrases') },
    { 'id': '2', 'image': '', 'title': loc.translate('millet'), 'title_sub': loc.translate('millet_phrases') },
    { 'id': '3', 'image': '', 'title': loc.translate('semolina'), 'title_sub': loc.translate('semolina_phrases') },
    { 'id': '4', 'image': '', 'title': loc.translate('bread'), 'title_sub': loc.translate('bread_phrases') },
    { 'id': '5', 'image': '', 'title': loc.translate('salt'), 'title_sub': loc.translate('salt_phrases') },
    { 'id': '6', 'image': '', 'title': loc.translate('sugar'), 'title_sub': loc.translate('sugar_phrases') },
    { 'id': '7', 'image': '', 'title': loc.translate('flour'), 'title_sub': loc.translate('flour_phrases') },
    { 'id': '8', 'image': '', 'title': loc.translate('nut'), 'title_sub': loc.translate('nut_phrases') },
    { 'id': '9', 'image': '', 'title': loc.translate('seeds'), 'title_sub': loc.translate('seeds_phrases') },
    { 'id': '10', 'image': '', 'title': loc.translate('groats'), 'title_sub': loc.translate('groats_phrases') },
    { 'id': '11', 'image': '', 'title': loc.translate('porridge'), 'title_sub': loc.translate('porridge_phrases') },
    { 'id': '12', 'image': '', 'title': loc.translate('macaroni'), 'title_sub': loc.translate('macaroni_phrases') },
    { 'id': '13', 'image': '', 'title': loc.translate('dough'), 'title_sub': loc.translate('dough_phrases') },
  ];
}

class DairyData {
  final BuildContext context; DairyData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late List<Map<String, dynamic>> dairyItem = [
    { 'id': '0', 'image': '', 'title': loc.translate('yoghurt'), 'title_sub': loc.translate('yoghurt_phrases') },
    { 'id': '1', 'image': '', 'title': loc.translate('kefir'), 'title_sub': loc.translate('kefir_phrases') },
    { 'id': '2', 'image': '', 'title': loc.translate('cottage_cheese'), 'title_sub': loc.translate('cottage_cheese_phrases') },
    { 'id': '3', 'image': '', 'title': loc.translate('butter'), 'title_sub': loc.translate('butter_phrases') },
    { 'id': '4', 'image': '', 'title': loc.translate('milk'), 'title_sub': loc.translate('milk_phrases') },
    { 'id': '5', 'image': '', 'title': loc.translate('cheese'), 'title_sub': loc.translate('cheese_phrases') },
    { 'id': '6', 'image': '', 'title': loc.translate('sour_cream'), 'title_sub': loc.translate('sour_cream_phrases') },
    { 'id': '7', 'image': '', 'title': loc.translate('oil'), 'title_sub': loc.translate('oil_phrases') },
    { 'id': '8', 'image': '', 'title': loc.translate('vegetable_oil'), 'title_sub': loc.translate('vegetable_oil_phrases') },
    { 'id': '9', 'image': '', 'title': loc.translate('ice_cream'), 'title_sub': loc.translate('ice_cream_phrases') },
    { 'id': '10', 'image': '', 'title': loc.translate('pancakes'), 'title_sub': loc.translate('pancakes_phrases') },
  ];
}