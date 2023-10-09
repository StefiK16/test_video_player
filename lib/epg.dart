class EPG {
  final String id;
  final String contentId;
  final String? eventId;
  final String baseContentId;
  final int stop;
  final String majorCategory;
  final String title;
  final String subtitle;
  final String? fullText;
  final String? shortText;
  final int start;
  final String chanName;
  final String chanId;
  final String? vendorsubtitle;
  final EpgNumeration numeration;
  final List<String>? categories;
  final int valid;
  final int majorId;
  final Rating? rating;
  final String? ageRestriction;
  final List<String>? actors;
  final List<String>? countries;
  final String? year;
  final String? originalTitle;
  final List<Photo>? photos;
  final int changets;
  final List<Person>? persons;
  final String? duration;
  final List<String>? minorCategories;
  final bool vod;
  final bool locked;
  final int validFrom;
  final List<Profile> profiles;

  EPG({
    required this.majorId,
    required this.id,
    required this.contentId,
    required this.eventId,
    required this.baseContentId,
    required this.shortText,
    required this.valid,
    required this.photos,
    required this.persons,
    required this.start,
    required this.stop,
    required this.majorCategory,
    required this.title,
    required this.chanName,
    required this.chanId,
    required this.vendorsubtitle,
    required this.categories,
    required this.numeration,
    required this.ageRestriction,
    required this.actors,
    required this.countries,
    required this.year,
    required this.originalTitle,
    required this.subtitle,
    required this.rating,
    required this.changets,
    required this.duration,
    required this.minorCategories,
    required this.fullText,
    this.locked = false,
    this.vod = false,
    this.validFrom = 0,
    this.profiles = const [],
  });
}

class Rating {
  final double? overall;
  final int? action;
  final int? depth;
  final int? humor;
  final int? suspense;
  final int? erotic;

  Rating({
    required this.overall,
    this.action,
    this.depth,
    this.humor,
    this.suspense,
    this.erotic,
  });

  bool get showRating {
    final actionRating = action ?? 0;
    final depthRating = depth ?? 0;
    final humorRating = humor ?? 0;
    final suspenseRating = suspense ?? 0;
    final eroticRating = erotic ?? 0;

    final total = actionRating +
        depthRating +
        humorRating +
        suspenseRating +
        eroticRating;

    return total > 0;
  }
}

class Photo {
  final PhotoType type;
  final String url;

  Photo({
    required this.type,
    required this.url,
  });
}

enum PhotoType {
  cover,
  wallpaper,
  thumbnail,
  poster,
}

class Person {
  final String function;
  final String name;

  Person({
    required this.function,
    required this.name,
  });
}

class Profile {
  final int id;
  final String name;
  final int bandwidth;
  final String codecs;
  final String resolution;
  final bool autoSelect;
  final bool defaultProfile;
  final bool private;

  Profile({
    required this.name,
    required this.private,
    required this.id,
    required this.defaultProfile,
    required this.codecs,
    required this.bandwidth,
    required this.autoSelect,
    required this.resolution,
  });
}

class EpgNumeration {
  int episodeNumber;
  final int seasonNumber;
  final int episodeCount;
  final int seasonCount;

  EpgNumeration({
    required this.episodeCount,
    required this.seasonCount,
    required this.episodeNumber,
    required this.seasonNumber,
  });
}
