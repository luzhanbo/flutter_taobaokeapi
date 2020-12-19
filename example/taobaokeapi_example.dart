import 'package:taobaokeapi/taobaokeapi.dart';
import 'config.dart';

TaobaokeAPI getClient(){
  return TaobaokeAPI(userToken: usertoken,defaultAdzoneId: adzoneId,defaultSiteId: siteId);
}

void testOneMonth() async{
  var client = getClient();
  final st = DateTime.now();
  var timeSpan = await client.getTimeSpan();
  var startTime = DateTime.now();
  var endTime = DateTime(2020,12,14);// lastMonthFirstDay();   //

  final orderStream = client.syncOrders(startTime: startTime, endTime: endTime,
      timeSpan: timeSpan,threads: 2,
      onFinish: (SyncProgress progress){
        print('Finish>>>>>>>>');
        print(progress.duration);
        print('Finish>>>>>>>>');
      },
      onProgress: (SyncProgress progress){
        print('finish ${(progress.finishRate*100).toStringAsFixed(2)}');
      }
  );
  var index = 0;
  orderStream.listen((order) {
    index++;
    if(index==1){
      var keys = order.keys;
      print('var orderFieldNames = [' + keys.map((e) => "'${e}'").join(',')+'];');
    }

  }).onDone(() {
    final et = DateTime.now();
    print('lastTime:${et.difference(st)}');
  });
}

void testSearch() async {
  var client = getClient();

  var ret = await client.search(q: '593142351635',pageSize: 1);

}

void testDetail() async {
  var client = getClient();
  var ret = await client.detail('59314235163500');
  print(ret);
}

void main() async {
  testOneMonth();

  // testSearch();
  // testDetail();
}
