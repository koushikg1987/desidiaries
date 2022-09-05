import 'package:news/Helper/String.dart';

//category model fetch category data from server side
class NotificationModel {
  String? id, image, message, date_sent, title, newsId, type, date;

  NotificationModel(
      {this.id,
      this.image,
      this.message,
      this.title,
      this.date_sent,
      this.newsId,
      this.type,
      this.date});

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return new NotificationModel(
        id: json[ID],
        image: json[IMAGE],
        message: json[MESSAGE],
        date_sent: json[DATE_SENT],
        newsId: json[NEWS_ID],
        title: json[TITLE],
        type: json[TYPE],
        date: json[DATE]);
  }
}
