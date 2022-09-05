import 'package:news/Helper/String.dart';

//category model fetch category data from server side
class BreakingNewsModel {
  String? id, image, title,desc;

  BreakingNewsModel(
      {this.id,
        this.image,
        this.title,
        this.desc
        });

  factory BreakingNewsModel.fromJson(Map<String, dynamic> json) {
    return new BreakingNewsModel(
        id: json[ID],
        image: json[IMAGE],
      title: json[TITLE],
      desc: json[DESCRIPTION],
    );
  }
}
