import 'package:active_ecommerce_flutter/app_config.dart';
import 'package:active_ecommerce_flutter/helpers/endpoints.dart';
import 'package:http/http.dart' as http;
import 'package:active_ecommerce_flutter/data_model/category_response.dart';
import 'package:active_ecommerce_flutter/helpers/shared_value_helper.dart';

class CategoryRepository {

  Future<CategoryResponse> getCategories({parent_id = 0}) async {
    Uri url = Uri.parse("${ENDP.GET_CATEGORIES}${parent_id}");
    final response =
    await http.get(url,headers: {
      "App-Language": app_language.$,
    });
    print("${ENDP.GET_CATEGORIES}${parent_id}");
    print(response.body.toString());
    return categoryResponseFromJson(response.body);
  }

  Future<CategoryResponse> getFeturedCategories() async {
    Uri url = Uri.parse("${ENDP.GET_FEATURED_CATEGORIES}");
    final response =
        await http.get(url,headers: {
          "App-Language": app_language.$,
        });
    //print(response.body.toString());
    //print("--featured cat--");
    return categoryResponseFromJson(response.body);
  }

  Future<CategoryResponse> getTopCategories() async {
    Uri url = Uri.parse("${ENDP.TOP_CATEGORIES}");
    final response =
    await http.get(url,headers: {
      "App-Language": app_language.$,
    });
    return categoryResponseFromJson(response.body);
  }

  Future<CategoryResponse> getFilterPageCategories() async {
    Uri url = Uri.parse("${ENDP.FILTER_CATEGORIES}");
    final response =
    await http.get(url,headers: {
      "App-Language": app_language.$,
    });
    return categoryResponseFromJson(response.body);
  }


}
