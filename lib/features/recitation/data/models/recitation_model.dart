class RecitationModel {
  final String id;
  final String textId;
  final String title;
  final String? language;

  RecitationModel({
    required this.id,
    required this.textId,
    required this.title,
    this.language,
  });

  factory RecitationModel.fromJson(Map<String, dynamic> json) {
    return RecitationModel(
      id: json['id'] as String,
      textId: json['text_id'] as String,
      title: json['title'] as String,
      language: json['language'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text_id': textId,
      'title': title,
      'language': language,
    };
  }

  RecitationModel copyWith({
    String? id,
    String? textId,
    String? title,
    String? language,
  }) {
    return RecitationModel(
      id: id ?? this.id,
      textId: textId ?? this.textId,
      title: title ?? this.title,
      language: language ?? this.language,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RecitationModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'RecitationModel(id: $id, textId: $textId, title: $title, language: $language)';
  }
}

final mockRecitations = [
  RecitationModel(
    id: '1',
    textId: '85eedd68-d56e-4086-bf0d-fd46cf9d0dfc',
    title: 'སྒྲོལ་མ་ཉེར་གཅིག་གི་བསྟོད་པ།.',
    language: 'en',
  ),
  RecitationModel(
    id: '2',
    textId: 'abda2074-753e-4472-8864-975b1c7da0c0',
    title:
        'སྒྲོལ་མ་ཕྱག་འཚལ་ཉི་ཤུ་རྩ་གཅིག་གི་བསྟོད་པའི་རྣམ་བཤད་གསལ་བའི་འོད་ཟེར་ཞེས་བྱ་བ་བཞུགས་སོ།',
    language: 'bo',
  ),
  RecitationModel(
    id: '3',
    textId: '607a80c5-65ac-4764-a3ca-1290de91987e',
    title: 'བསྟོད་པའི་རྣམ་བཤད་གསལ་བའི་འོད་ཟེར་བཞུགས། ',
    language: 'bo',
  ),
  RecitationModel(
    id: '4',
    textId: 'f6d18089-518b-4720-b6dc-47c33e2df1df',
    title: 'Prayer of Dolma',
    language: 'bo',
  ),
  RecitationModel(
    id: '5',
    textId: 'd227c1eb-68cf-4dca-ba4b-81f4d45bd1b0',
    title: 'The twenty-one praises of the Dolma are called the clear light',
    language: 'en',
  ),
  RecitationModel(
    id: '6',
    textId: 'bf51227a-18dd-4e4b-9174-fe413ad30159',
    title: '二十一首卓玛赞歌，名为清净光明',
    language: 'zh',
  ),
];
