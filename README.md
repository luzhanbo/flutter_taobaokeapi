淘宝客API的dart SDK.

## 使用方法

```dart
import 'package:taobaokeapi/taobaokeapi.dart';

main() {
  //usertoken 在https://taobaokeapi.com/获取
  var client = TaobaokeAPI(userToken: usertoken,defaultAdzoneId: adzoneId,defaultSiteId: siteId);
  //搜索 
  var ret = await client.search(q: '苹果');
}
```

```dart
//订单同步
void testOneMonth() async{
  var client = getClient();
  final st = DateTime.now();
  var timeSpan = await client.getTimeSpan();
  var startTime = DateTime.now();
  var endTime = lastMonthFirstDay();

  final orderStream = client.syncOrders(startTime: startTime, endTime: endTime,
      timeSpan: timeSpan,threads: 2,
      onFinish: (SyncProgress progress){
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
      print(order);
    }

  }).onDone(() {
    final et = DateTime.now();
    print('lastTime:${et.difference(st)}');
  });
}

```

