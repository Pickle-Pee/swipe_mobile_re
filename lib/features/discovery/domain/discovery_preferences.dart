const _unsetPreferenceValue = Object();

class DiscoveryPreferences {
  const DiscoveryPreferences({
    this.minAge,
    this.maxAge,
    this.smokingAttitude,
    this.alcoholAttitude,
    this.childrenPreference,
    this.whatLookingFor,
    this.appearance,
    this.religion,
  });

  static const empty = DiscoveryPreferences();
  static const attributeKeys = [
    'what_looking_for',
    'smoking_attitude',
    'alcohol_attitude',
    'children_preference',
    'appearance',
    'religion',
  ];

  final int? minAge;
  final int? maxAge;
  final String? smokingAttitude;
  final String? alcoholAttitude;
  final String? childrenPreference;
  final String? whatLookingFor;
  final String? appearance;
  final String? religion;

  String? valueFor(String key) => switch (key) {
    'smoking_attitude' => smokingAttitude,
    'alcohol_attitude' => alcoholAttitude,
    'children_preference' => childrenPreference,
    'what_looking_for' => whatLookingFor,
    'appearance' => appearance,
    'religion' => religion,
    _ => null,
  };

  DiscoveryPreferences copyWith({
    Object? minAge = _unsetPreferenceValue,
    Object? maxAge = _unsetPreferenceValue,
    Object? smokingAttitude = _unsetPreferenceValue,
    Object? alcoholAttitude = _unsetPreferenceValue,
    Object? childrenPreference = _unsetPreferenceValue,
    Object? whatLookingFor = _unsetPreferenceValue,
    Object? appearance = _unsetPreferenceValue,
    Object? religion = _unsetPreferenceValue,
  }) => DiscoveryPreferences(
    minAge: identical(minAge, _unsetPreferenceValue)
        ? this.minAge
        : minAge as int?,
    maxAge: identical(maxAge, _unsetPreferenceValue)
        ? this.maxAge
        : maxAge as int?,
    smokingAttitude: identical(smokingAttitude, _unsetPreferenceValue)
        ? this.smokingAttitude
        : _cleanText(smokingAttitude),
    alcoholAttitude: identical(alcoholAttitude, _unsetPreferenceValue)
        ? this.alcoholAttitude
        : _cleanText(alcoholAttitude),
    childrenPreference: identical(childrenPreference, _unsetPreferenceValue)
        ? this.childrenPreference
        : _cleanText(childrenPreference),
    whatLookingFor: identical(whatLookingFor, _unsetPreferenceValue)
        ? this.whatLookingFor
        : _cleanText(whatLookingFor),
    appearance: identical(appearance, _unsetPreferenceValue)
        ? this.appearance
        : _cleanText(appearance),
    religion: identical(religion, _unsetPreferenceValue)
        ? this.religion
        : _cleanText(religion),
  );

  DiscoveryPreferences copyWithAttribute(String key, String? value) =>
      switch (key) {
        'smoking_attitude' => copyWith(smokingAttitude: value),
        'alcohol_attitude' => copyWith(alcoholAttitude: value),
        'children_preference' => copyWith(childrenPreference: value),
        'what_looking_for' => copyWith(whatLookingFor: value),
        'appearance' => copyWith(appearance: value),
        'religion' => copyWith(religion: value),
        _ => this,
      };

  Map<String, dynamic> toQueryParameters() {
    final result = <String, dynamic>{};
    if (minAge != null) result['minAge'] = minAge;
    if (maxAge != null) result['maxAge'] = maxAge;
    for (final key in attributeKeys) {
      final value = valueFor(key);
      if (value == null) continue;
      result[_queryName(key)] = value;
    }
    return result;
  }

  Map<String, dynamic> toJson() => {
    'min_age': minAge,
    'max_age': maxAge,
    for (final key in attributeKeys) key: valueFor(key),
  };

  factory DiscoveryPreferences.fromJson(Map<String, dynamic> json) {
    int? optionalInt(String key) {
      final value = json[key];
      if (value == null) return null;
      if (value is int) return value;
      throw FormatException('$key must be an integer');
    }

    String? optionalText(String key) {
      final value = json[key];
      if (value == null) return null;
      if (value is! String) throw FormatException('$key must be a string');
      return _cleanText(value);
    }

    return DiscoveryPreferences(
      minAge: optionalInt('min_age'),
      maxAge: optionalInt('max_age'),
      smokingAttitude: optionalText('smoking_attitude'),
      alcoholAttitude: optionalText('alcohol_attitude'),
      childrenPreference: optionalText('children_preference'),
      whatLookingFor: optionalText('what_looking_for'),
      appearance: optionalText('appearance'),
      religion: optionalText('religion'),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is DiscoveryPreferences &&
      other.minAge == minAge &&
      other.maxAge == maxAge &&
      other.smokingAttitude == smokingAttitude &&
      other.alcoholAttitude == alcoholAttitude &&
      other.childrenPreference == childrenPreference &&
      other.whatLookingFor == whatLookingFor &&
      other.appearance == appearance &&
      other.religion == religion;

  @override
  int get hashCode => Object.hash(
    minAge,
    maxAge,
    smokingAttitude,
    alcoholAttitude,
    childrenPreference,
    whatLookingFor,
    appearance,
    religion,
  );
}

class DiscoveryPreferencesDraft {
  const DiscoveryPreferencesDraft({
    this.minAge = '',
    this.maxAge = '',
    this.filters = DiscoveryPreferences.empty,
  });

  final String minAge;
  final String maxAge;
  final DiscoveryPreferences filters;

  factory DiscoveryPreferencesDraft.fromPreferences(
    DiscoveryPreferences preferences,
  ) => DiscoveryPreferencesDraft(
    minAge: preferences.minAge?.toString() ?? '',
    maxAge: preferences.maxAge?.toString() ?? '',
    filters: preferences,
  );

  String? get validationMessage {
    final minimum = minAge.trim();
    final maximum = maxAge.trim();
    if (minimum.isEmpty && maximum.isEmpty) return null;
    if (minimum.isEmpty || maximum.isEmpty) {
      return 'Enter both ages, or leave both empty for the automatic range.';
    }
    final parsedMinimum = int.tryParse(minimum);
    final parsedMaximum = int.tryParse(maximum);
    if (parsedMinimum == null || parsedMaximum == null) {
      return 'Use whole numbers for both ages.';
    }
    if (parsedMinimum < 18 || parsedMaximum < 18) {
      return 'Both ages must be at least 18.';
    }
    if (parsedMinimum > parsedMaximum) {
      return 'Minimum age must not be greater than maximum age.';
    }
    return null;
  }

  DiscoveryPreferences? get validatedPreferences {
    if (validationMessage != null) return null;
    final minimum = minAge.trim();
    final maximum = maxAge.trim();
    return filters.copyWith(
      minAge: minimum.isEmpty ? null : int.parse(minimum),
      maxAge: maximum.isEmpty ? null : int.parse(maximum),
    );
  }

  DiscoveryPreferencesDraft copyWith({
    String? minAge,
    String? maxAge,
    DiscoveryPreferences? filters,
  }) => DiscoveryPreferencesDraft(
    minAge: minAge ?? this.minAge,
    maxAge: maxAge ?? this.maxAge,
    filters: filters ?? this.filters,
  );

  DiscoveryPreferencesDraft copyWithAttribute(String key, String? value) =>
      copyWith(filters: filters.copyWithAttribute(key, value));

  @override
  bool operator ==(Object other) =>
      other is DiscoveryPreferencesDraft &&
      other.minAge == minAge &&
      other.maxAge == maxAge &&
      other.filters == filters;

  @override
  int get hashCode => Object.hash(minAge, maxAge, filters);
}

String? _cleanText(Object? value) {
  if (value == null) return null;
  final text = '$value'.trim();
  return text.isEmpty ? null : text;
}

String _queryName(String key) => switch (key) {
  'smoking_attitude' => 'smokingAttitude',
  'alcohol_attitude' => 'alcoholAttitude',
  'children_preference' => 'childrenPreference',
  'what_looking_for' => 'whatLookingFor',
  'appearance' => 'appearance',
  'religion' => 'religion',
  _ => throw ArgumentError.value(key, 'key', 'Unsupported Discovery filter'),
};
