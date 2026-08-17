import '../../../auth/data/models/location_models.dart';
import 'searchable_picker_sheet.dart';

List<SearchablePickerItem<Country>> countryPickerItems(List<Country> countries) {
  return countries
      .map((c) {
        final code = (c.phoneCode ?? '').replaceAll('+', '').trim();
        return SearchablePickerItem<Country>(
          value: c,
          label: c.name,
          subtitle: code.isEmpty ? null : '+$code',
          leading: (c.emoji == null || c.emoji!.isEmpty) ? null : c.emoji,
          searchText: '${c.name} ${c.iso2} +$code ${c.emoji ?? ''}',
        );
      })
      .toList(growable: false);
}

List<SearchablePickerItem<StateModel>> statePickerItems(List<StateModel> states) {
  return states
      .map(
        (s) => SearchablePickerItem<StateModel>(
          value: s,
          label: s.name,
          searchText: '${s.name} ${s.iso2}',
        ),
      )
      .toList(growable: false);
}

List<SearchablePickerItem<CityModel>> cityPickerItems(List<CityModel> cities) {
  return cities
      .map(
        (c) => SearchablePickerItem<CityModel>(
          value: c,
          label: c.name,
          searchText: c.name,
        ),
      )
      .toList(growable: false);
}
