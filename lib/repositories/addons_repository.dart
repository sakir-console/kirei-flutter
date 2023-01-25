import 'package:active_ecommerce_flutter/app_config.dart';
import 'package:active_ecommerce_flutter/data_model/addons_response.dart';
import 'package:active_ecommerce_flutter/helpers/endpoints.dart';
import 'package:http/http.dart' as http;

class AddonsRepository{
Future<List<AddonsListResponse>> getAddonsListResponse() async{
  Uri url = Uri.parse('${ENDP.AddOns}');

  final response = await http.get(url);
  print("adons ${response.body}");
  return addonsListResponseFromJson(response.body);
}
}