import 'package:news/Helper/String.dart';

//category model fetch category data from server side
class Category {
  String? id, image, categoryName, categoryId;
  List<SubCategory>? subData;

  Category(
      {this.id, this.image, this.categoryName, this.categoryId, this.subData});

  factory Category.fromJson(Map<String, dynamic> json) {
    var subList = (json[SUBCATEGORY] as List);
    List<SubCategory> subCatData = [];
    if (subList == null || subList.isEmpty)
      subList = [];
    else
      subCatData =
          subList.map((data) => new SubCategory.fromJson(data)).toList();
    return new Category(
      id: json[ID],
      image: json[IMAGE],
      categoryName: json[CATEGORY_NAME],
      categoryId: json[CATEGORY_ID],
      subData: subCatData,
    );
  }
}

class SubCategory {
  String? id, image, categoryId, subCatName;

  SubCategory({this.id, this.image, this.categoryId, this.subCatName});

  factory SubCategory.fromJson(Map<String, dynamic> json) {
    return new SubCategory(
        id: json[ID],
        image: json[IMAGE],
        categoryId: json[CATEGORY_ID],
        subCatName: json[SUBCAT_NAME]);
  }
}
