import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

class PageFamily {
  final BuildContext context; PageFamily({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late List<Map<String, dynamic>> famItem = [
    { 'id': '0', 'image': '', 'title': loc.translate('father'), 'title_sub': loc.translate('father_phrases') },
    { 'id': '1', 'image': '', 'title': loc.translate('mother'), 'title_sub': loc.translate('mother_phrases') },
    { 'id': '2', 'image': '', 'title': loc.translate('parents'), 'title_sub': loc.translate('parents_phrases') },
    { 'id': '3', 'image': '', 'title': loc.translate('brother'), 'title_sub': loc.translate('brother_phrases') },
    { 'id': '4', 'image': '', 'title': loc.translate('sister'), 'title_sub': loc.translate('sister_phrases') },
    { 'id': '5', 'image': '', 'title': loc.translate('siblings'), 'title_sub': loc.translate('siblings_phrases') },
    { 'id': '6', 'image': '', 'title': loc.translate('son'), 'title_sub': loc.translate('son_phrases') },
    { 'id': '7', 'image': '', 'title': loc.translate('daughter'), 'title_sub': loc.translate('daughter_phrases') },
    { 'id': '8', 'image': '', 'title': loc.translate('children'), 'title_sub': loc.translate('children_phrases') },
    { 'id': '9', 'image': '', 'title': loc.translate('child'), 'title_sub': loc.translate('child_phrases') },
    { 'id': '10', 'image': '', 'title': loc.translate('baby'), 'title_sub': loc.translate('baby_phrases') },
    { 'id': '11', 'image': '', 'title': loc.translate('elder_brother'), 'title_sub': loc.translate('elder_brother_phrases') },
    { 'id': '12', 'image': '', 'title': loc.translate('elder_sister'), 'title_sub': loc.translate('elder_sister_phrases') },
    { 'id': '13', 'image': '', 'title': loc.translate('younger_brother'), 'title_sub': loc.translate('younger_brother_phrases') },
    { 'id': '14', 'image': '', 'title': loc.translate('younger_sister'), 'title_sub': loc.translate('younger_sister_phrases') },
    { 'id': '15', 'image': '', 'title': loc.translate('person'), 'title_sub': loc.translate('person_phrases') },
    { 'id': '16', 'image': '', 'title': loc.translate('man'), 'title_sub': loc.translate('man_phrases') },
    { 'id': '17', 'image': '', 'title': loc.translate('woman'), 'title_sub': loc.translate('woman_phrases') },
    { 'id': '18', 'image': '', 'title': loc.translate('boy'), 'title_sub': loc.translate('boy_phrases') },
    { 'id': '19', 'image': '', 'title': loc.translate('girl'), 'title_sub': loc.translate('girl_phrases') },
    { 'id': '20', 'image': '', 'title': loc.translate('twin'), 'title_sub': loc.translate('twin_phrases') },
    { 'id': '21', 'image': '', 'title': loc.translate('twin_brother'), 'title_sub': loc.translate('twin_brother_phrases') },
    { 'id': '22', 'image': '', 'title': loc.translate('twin_sister'), 'title_sub': loc.translate('twin_sister_phrases') },
  ];
}

class PageExtendedFamily {
  final BuildContext context; PageExtendedFamily({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late List<Map<String, dynamic>> famItem = [
    { 'id': '0', 'image': '', 'title': loc.translate('grandfather'), 'title_sub': loc.translate('grandfather_phrases') },
    { 'id': '1', 'image': '', 'title': loc.translate('grandmother'), 'title_sub': loc.translate('grandmother_phrases') },
    { 'id': '2', 'image': '', 'title': loc.translate('grandparents'), 'title_sub': loc.translate('grandparents_phrases') },
    { 'id': '3', 'image': '', 'title': loc.translate('uncle'), 'title_sub': loc.translate('uncle_phrases') },
    { 'id': '4', 'image': '', 'title': loc.translate('aunt'), 'title_sub': loc.translate('aunt_phrases') },
    { 'id': '5', 'image': '', 'title': loc.translate('cousin'), 'title_sub': loc.translate('cousin_phrases') },
    { 'id': '6', 'image': '', 'title': loc.translate('niece'), 'title_sub': loc.translate('niece_phrases') },
    { 'id': '7', 'image': '', 'title': loc.translate('nephew'), 'title_sub': loc.translate('nephew_phrases') },
    { 'id': '8', 'image': '', 'title': loc.translate('relative'), 'title_sub': loc.translate('relative_phrases') },
    { 'id': '9', 'image': '', 'title': loc.translate('countrywoman'), 'title_sub': loc.translate('countrywoman_phrases') },
    { 'id': '10', 'image': '', 'title': loc.translate('generation'), 'title_sub': loc.translate('generation_phrases') },
    { 'id': '11', 'image': '', 'title': loc.translate('teenager'), 'title_sub': loc.translate('teenager_phrases') },
  ];
}

class PartnersExesData {
  final BuildContext context; PartnersExesData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late List<Map<String, dynamic>> famItem = [
    { 'id': '0', 'image': '', 'title': loc.translate('bride'), 'title_sub': loc.translate('bride_phrases') },
    { 'id': '1', 'image': '', 'title': loc.translate('groom'), 'title_sub': loc.translate('groom_phrases') },
    { 'id': '2', 'image': '', 'title': loc.translate('marriage'), 'title_sub': loc.translate('marriage_phrases') },
    { 'id': '3', 'image': '', 'title': loc.translate('spouse'), 'title_sub': loc.translate('spouse_phrases') },
    { 'id': '4', 'image': '', 'title': loc.translate('divorce'), 'title_sub': loc.translate('divorce_phrases') },
    { 'id': '5', 'image': '', 'title': loc.translate('bachelor'), 'title_sub': loc.translate('bachelor_phrases') },
    { 'id': '6', 'image': '', 'title': loc.translate('lover'), 'title_sub': loc.translate('lover_phrases') },
    { 'id': '7', 'image': '', 'title': loc.translate('pretty'), 'title_sub': loc.translate('pretty_phrases') },
    { 'id': '8', 'image': '', 'title': loc.translate('husband'), 'title_sub': loc.translate('husband_phrases') },
    { 'id': '9', 'image': '', 'title': loc.translate('wife'), 'title_sub': loc.translate('wife_phrases') },
  ];
}

class HouseholdLineageTermsData {
  final BuildContext context; HouseholdLineageTermsData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late List<Map<String, dynamic>> famItem = [
    { 'id': '0', 'image': '', 'title': loc.translate('family'), 'title_sub': loc.translate('family_phrases') },
    { 'id': '1', 'image': '', 'title': loc.translate('youth'), 'title_sub': loc.translate('youth_phrases') },
    { 'id': '2', 'image': '', 'title': loc.translate('unfortunate'), 'title_sub': loc.translate('unfortunate_phrases') },
    { 'id': '3', 'image': '', 'title': loc.translate('rich'), 'title_sub': loc.translate('rich_phrases') },
    { 'id': '4', 'image': '', 'title': loc.translate('poor'), 'title_sub': loc.translate('poor_phrases') },
    { 'id': '5', 'image': '', 'title': loc.translate('to_respect'), 'title_sub': loc.translate('to_respect_phrases') },
    { 'id': '6', 'image': '', 'title': loc.translate('to_live'), 'title_sub': loc.translate('to_live_phrases') },
  ];
}

class BirthOrderMultiplesData {
  final BuildContext context; BirthOrderMultiplesData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late List<Map<String, dynamic>> famItem = [
    { 'id': '0', 'image': '', 'title': loc.translate('grown_up'), 'title_sub': loc.translate('grown_up_phrases') },
    { 'id': '1', 'image': '', 'title': loc.translate('adult'), 'title_sub': loc.translate('adult_phrases') },
    { 'id': '2', 'image': '', 'title': loc.translate('elder'), 'title_sub': loc.translate('elder_phrases') },
    { 'id': '3', 'image': '', 'title': loc.translate('younger'), 'title_sub': loc.translate('younger_phrases') },
    { 'id': '4', 'image': '', 'title': loc.translate('widow'), 'title_sub': loc.translate('widow_phrases') },
    { 'id': '5', 'image': '', 'title': loc.translate('widower'), 'title_sub': loc.translate('widower_phrases') },
    { 'id': '6', 'image': '', 'title': loc.translate('to_be_born'), 'title_sub': loc.translate('to_be_born_phrases') },
    { 'id': '7', 'image': '', 'title': loc.translate('tall'), 'title_sub': loc.translate('tall_phrases') },
    { 'id': '8', 'image': '', 'title': loc.translate('little'), 'title_sub': loc.translate('little_phrases') },
    { 'id': '9', 'image': '', 'title': loc.translate('thick'), 'title_sub': loc.translate('thick_phrases') },
    { 'id': '10', 'image': '', 'title': loc.translate('ill'), 'title_sub': loc.translate('ill_phrases') },
    { 'id': '11', 'image': '', 'title': loc.translate('thin'), 'title_sub': loc.translate('thin_phrases') },
    { 'id': '12', 'image': '', 'title': loc.translate('young'), 'title_sub': loc.translate('young_phrases') },
    { 'id': '13', 'image': '', 'title': loc.translate('death'), 'title_sub': loc.translate('death_phrases') },
    { 'id': '14', 'image': '', 'title': loc.translate('to_die'), 'title_sub': loc.translate('to_die_phrases') },
  ];
}