// ignore_for_file: constant_identifier_names

enum SmokingAttitudeEnum {
  NON_SMOKER,
  SOMETIMES,
  REGULAR_SMOKER,
  TRYING_TO_QUIT,
  NOT_OPPOSED,
  STYLE_LIFE,
}

extension SmokingAttitudeExtension on SmokingAttitudeEnum {
  String get value {
    switch (this) {
      case SmokingAttitudeEnum.NON_SMOKER:
        return "Не курю";
      case SmokingAttitudeEnum.SOMETIMES:
        return "Иногда на вечеринках";
      case SmokingAttitudeEnum.REGULAR_SMOKER:
        return "Любитель/Любительница сигарет";
      case SmokingAttitudeEnum.TRYING_TO_QUIT:
        return "В поисках силы воли";
      case SmokingAttitudeEnum.NOT_OPPOSED:
        return "Не против, но предпочитаю не курить";
      case SmokingAttitudeEnum.STYLE_LIFE:
        return "Тату и сигареты";
    }
  }

  static SmokingAttitudeEnum fromString(String value) {
    switch (value) {
      case "Не курю":
        return SmokingAttitudeEnum.NON_SMOKER;
      case "Иногда на вечеринках":
        return SmokingAttitudeEnum.SOMETIMES;
      case "Любитель/Любительница сигарет":
        return SmokingAttitudeEnum.REGULAR_SMOKER;
      case "В поисках силы воли":
        return SmokingAttitudeEnum.TRYING_TO_QUIT;
      case "Не против, но предпочитаю не курить":
        return SmokingAttitudeEnum.NOT_OPPOSED;
      case "Тату и сигареты":
        return SmokingAttitudeEnum.STYLE_LIFE;
      default:
        throw Exception('Unknown SmokingAttitudeEnum value: $value');
    }
  }
}

enum AlcoholAttitudeEnum {
  ABSTAIN,
  ENJOY_SIP,
  PARTY_EVERY_DAY,
  MODERATE,
  COCKTAIL_MASTER,
  HERBAL_TEA,
}

extension AlcoholAttitudeExtension on AlcoholAttitudeEnum {
  String get value {
    switch (this) {
      case AlcoholAttitudeEnum.ABSTAIN:
        return "Безалкогольный образ жизни";
      case AlcoholAttitudeEnum.ENJOY_SIP:
        return "Люблю посидеть за бокалом";
      case AlcoholAttitudeEnum.PARTY_EVERY_DAY:
        return "Вечеринка каждый день";
      case AlcoholAttitudeEnum.MODERATE:
        return "Умеренно";
      case AlcoholAttitudeEnum.COCKTAIL_MASTER:
        return "Коктейльный мастер";
      case AlcoholAttitudeEnum.HERBAL_TEA:
        return "Травяной чай и безалкогольные напитки";
    }
  }

  static AlcoholAttitudeEnum fromString(String value) {
    switch (value) {
      case "Безалкогольный образ жизни":
        return AlcoholAttitudeEnum.ABSTAIN;
      case "Люблю посидеть за бокалом":
        return AlcoholAttitudeEnum.ENJOY_SIP;
      case "Вечеринка каждый день":
        return AlcoholAttitudeEnum.PARTY_EVERY_DAY;
      case "Умеренно":
        return AlcoholAttitudeEnum.MODERATE;
      case "Коктейльный мастер":
        return AlcoholAttitudeEnum.COCKTAIL_MASTER;
      case "Травяной чай и безалкогольные напитки":
        return AlcoholAttitudeEnum.HERBAL_TEA;
      default:
        throw Exception('Unknown AlcoholAttitudeEnum value: $value');
    }
  }
}

enum WhatLookingForEnum {
  TRUE_LOVE,
  NEW_FRIENDS,
  ADVENTURES,
  SERIOUS_RELATIONSHIP,
  TRAVEL,
  UNDERSTANDING,
  FRIENDSHIP_WITH_BENEFITS,
}

extension WhatLookingForExtension on WhatLookingForEnum {
  String get value {
    switch (this) {
      case WhatLookingForEnum.TRUE_LOVE:
        return "Истинная любовь";
      case WhatLookingForEnum.NEW_FRIENDS:
        return "Новые друзья";
      case WhatLookingForEnum.ADVENTURES:
        return "Приключения и веселье";
      case WhatLookingForEnum.SERIOUS_RELATIONSHIP:
        return "Серьёзные отношения с перспективой брака";
      case WhatLookingForEnum.TRAVEL:
        return "Путешествия вместе";
      case WhatLookingForEnum.UNDERSTANDING:
        return "Взаимопонимание и поддержка";
      case WhatLookingForEnum.FRIENDSHIP_WITH_BENEFITS:
        return "Дружба с выгодой";
    }
  }

  static WhatLookingForEnum fromString(String value) {
    switch (value) {
      case "Истинная любовь":
        return WhatLookingForEnum.TRUE_LOVE;
      case "Новые друзья":
        return WhatLookingForEnum.NEW_FRIENDS;
      case "Приключения и веселье":
        return WhatLookingForEnum.ADVENTURES;
      case "Серьёзные отношения с перспективой брака":
        return WhatLookingForEnum.SERIOUS_RELATIONSHIP;
      case "Путешествия вместе":
        return WhatLookingForEnum.TRAVEL;
      case "Взаимопонимание и поддержка":
        return WhatLookingForEnum.UNDERSTANDING;
      case "Дружба с выгодой":
        return WhatLookingForEnum.FRIENDSHIP_WITH_BENEFITS;
      default:
        throw Exception('Unknown WhatLookingForEnum value: $value');
    }
  }
}

enum ReligionEnum {
  ATHEIST,
  ORTHODOX,
  CATHOLIC,
  MUSLIM,
  BUDDHIST,
  HINDU,
  SPIRITUAL,
  JUDAIST,
  OTHER,
  PREFERS_NOT_TO_SAY,
}

extension ReligionExtension on ReligionEnum {
  String get value {
    switch (this) {
      case ReligionEnum.ATHEIST:
        return "Атеист/Атеистка";
      case ReligionEnum.ORTHODOX:
        return "Православный/Православная";
      case ReligionEnum.CATHOLIC:
        return "Католик/Католичка";
      case ReligionEnum.MUSLIM:
        return "Мусульманин/Мусульманка";
      case ReligionEnum.BUDDHIST:
        return "Буддист/Буддистка";
      case ReligionEnum.HINDU:
        return "Индуист/Индуистка";
      case ReligionEnum.SPIRITUAL:
        return "Духовно, но не религиозен(на)";
      case ReligionEnum.JUDAIST:
        return "Иудаист/Иудаистка";
      case ReligionEnum.OTHER:
        return "Другие религии";
      case ReligionEnum.PREFERS_NOT_TO_SAY:
        return "Предпочитаю не указывать";
    }
  }

  static ReligionEnum fromString(String value) {
    switch (value) {
      case "Атеист/Атеистка":
        return ReligionEnum.ATHEIST;
      case "Православный/Православная":
        return ReligionEnum.ORTHODOX;
      case "Католик/Католичка":
        return ReligionEnum.CATHOLIC;
      case "Мусульманин/Мусульманка":
        return ReligionEnum.MUSLIM;
      case "Буддист/Буддистка":
        return ReligionEnum.BUDDHIST;
      case "Индуист/Индуистка":
        return ReligionEnum.HINDU;
      case "Духовно, но не религиозен(на)":
        return ReligionEnum.SPIRITUAL;
      case "Иудаист/Иудаистка":
        return ReligionEnum.JUDAIST;
      case "Другие религии":
        return ReligionEnum.OTHER;
      case "Предпочитаю не указывать":
        return ReligionEnum.PREFERS_NOT_TO_SAY;
      default:
        throw Exception('Unknown ReligionEnum value: $value');
    }
  }
}

enum ChildrenEnum {
  PLANNING_CHILDREN,
  HAVE_CHILDREN,
  CHILDREN_OUTGROWN,
  OPEN_TO_PARTNER_CHILDREN,
  NO_CHILDREN,
}

extension ChildrenEnumExtension on ChildrenEnum {
  String get value {
    switch (this) {
      case ChildrenEnum.PLANNING_CHILDREN:
        return "Планирую детей в будущем";
      case ChildrenEnum.HAVE_CHILDREN:
        return "Есть дети, и они занимают моё сердце";
      case ChildrenEnum.CHILDREN_OUTGROWN:
        return "Дети уже выросли и самостоятельны";
      case ChildrenEnum.OPEN_TO_PARTNER_CHILDREN:
        return "Не против детей у партнера";
      case ChildrenEnum.NO_CHILDREN:
        return "Нет детей, и это меня устраивает";
    }
  }

  static ChildrenEnum fromString(String value) {
    switch (value) {
      case "Планирую детей в будущем":
        return ChildrenEnum.PLANNING_CHILDREN;
      case "Есть дети, и они занимают моё сердце":
        return ChildrenEnum.HAVE_CHILDREN;
      case "Дети уже выросли и самостоятельны":
        return ChildrenEnum.CHILDREN_OUTGROWN;
      case "Не против детей у партнера":
        return ChildrenEnum.OPEN_TO_PARTNER_CHILDREN;
      case "Нет детей, и это меня устраивает":
        return ChildrenEnum.NO_CHILDREN;
      default:
        throw Exception('Unknown ChildrenEnum value: $value');
    }
  }
}

enum AppearanceEnum {
  ACTIVE_LIFESTYLE,
  FASHION_FORWARD,
  NATURAL_SIMPLE,
  REFINED_STYLE,
  TATTOO_PIERCING,
  TIMELY_CLASSIC,
  EXPERIMENTAL_STYLE,
  SOFT_KIND_APPEARANCE,
}

extension AppearanceEnumExtension on AppearanceEnum {
  String get value {
    switch (this) {
      case AppearanceEnum.ACTIVE_LIFESTYLE:
        return "Активный образ жизни и забота о теле.";
      case AppearanceEnum.FASHION_FORWARD:
        return "Люблю моду и следую последним трендам.";
      case AppearanceEnum.NATURAL_SIMPLE:
        return "Предпочитаю натуральный и простой вид.";
      case AppearanceEnum.REFINED_STYLE:
        return "Обожаю изысканный и утончённый стиль.";
      case AppearanceEnum.TATTOO_PIERCING:
        return "Носитель татуировок и пирсинга.";
      case AppearanceEnum.TIMELY_CLASSIC:
        return "Предпочитаю вечную классику в одежде и внешности.";
      case AppearanceEnum.EXPERIMENTAL_STYLE:
        return "Люблю выделяться и экспериментировать со стилем.";
      case AppearanceEnum.SOFT_KIND_APPEARANCE:
        return "Внешность отражает мягкость и доброту.";
    }
  }

  static AppearanceEnum fromString(String value) {
    switch (value) {
      case "Активный образ жизни и забота о теле.":
        return AppearanceEnum.ACTIVE_LIFESTYLE;
      case "Люблю моду и следую последним трендам.":
        return AppearanceEnum.FASHION_FORWARD;
      case "Предпочитаю натуральный и простой вид.":
        return AppearanceEnum.NATURAL_SIMPLE;
      case "Обожаю изысканный и утончённый стиль.":
        return AppearanceEnum.REFINED_STYLE;
      case "Носитель татуировок и пирсинга.":
        return AppearanceEnum.TATTOO_PIERCING;
      case "Предпочитаю вечную классику в одежде и внешности.":
        return AppearanceEnum.TIMELY_CLASSIC;
      case "Люблю выделяться и экспериментировать со стилем.":
        return AppearanceEnum.EXPERIMENTAL_STYLE;
      case "Внешность отражает мягкость и доброту.":
        return AppearanceEnum.SOFT_KIND_APPEARANCE;
      default:
        throw Exception('Unknown AppearanceEnum value: $value');
    }
  }
}
