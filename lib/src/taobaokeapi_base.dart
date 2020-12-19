import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'time_utils.dart';

const root = 'https://api.taobaokeapi.com/';

typedef ProgressCallback = void Function(SyncProgress);
typedef FinishCallback = void Function(SyncProgress);

class TaobaokeAPI {
  final String userToken;
  final int defaultSiteId;
  final int defaultAdzoneId;

  TaobaokeAPI({this.userToken,this.defaultAdzoneId,this.defaultSiteId }):assert(userToken!=null);

  Future<Map<String,dynamic>> execute(String method,Map<String,dynamic> params) async{
    var url = '${root}?usertoken=${userToken}&method=${method}';
    var res = await Dio().post(url, data: params);
    return jsonDecode(res.toString()) as Map<String, dynamic>;
  }

  Future<Map<String,dynamic>> search({String q,int pageNo=1,int pageSize=40,
          bool withCoupon=false,bool freeShipment=false,bool isTmall=false,
          int siteId,int adzoneId,
  }) async{
    var method = 'taobao.tbk.sc.material.optional';
    var id = int.tryParse(q);
    if(id!=null){
      q = 'https://item.taobao.com/item.htm?id=${id}';
    }
    var params = {'site_id':siteId??defaultSiteId,
                  'adzone_id':adzoneId??defaultAdzoneId,'q':q};

    if(id==null){
      if(withCoupon){
        params['has_coupon'] = true;
      }
      if(freeShipment){
        params['need_free_shipment'] = true;
      }
      if(isTmall){
        params['is_tmall'] = true;
      }
      params['page_no'] = pageNo;
      params['page_size'] = pageSize;
    }

    var ret = await execute(method, params);
    return ret;
  }

  Future<String> tkl({String url,String logo,String text}) async{
    var method = 'taobao.tbk.tpwd.create';
    if(url.startsWith('//')){
      url = 'https:$url';
    }
    var params = {'url':url,'logo':logo,'text':text};
    // print(params);
    var ret = await execute(method, params);
    var errMsg = ret['sub_msg'];
    if(errMsg!=null){
      return errMsg;
    }else{
      return ret['data']['model'];
    }
  }

  Future<Map<String,dynamic>> detail(String id) async {
      var ret = await search(q:id);
      var data = ret['result_list'];
      if(data!=null){
        return data['map_data'];
      }
      return null;
  }

  Stream<Map<String,dynamic>> _syncOneTimeOrder({String startTime,String endTime,
    int pageSize,int pageNo,String positionIndex,String queryType}) async*{
    var method = 'taobao.tbk.sc.order.details.get';
    var params = <String,dynamic>{'end_time':endTime,'start_time':startTime};
    if(pageSize!=null){
      params['page_size'] = pageSize;
    }else{
      params['page_size'] = 100;
    }
    if(pageNo!=null){
      params['page_no'] = pageNo;
    }
    if(positionIndex!=null){
      params['position_index'] = positionIndex;
    }
    if(queryType!=null){
      params['query_type'] = queryType;
    }
    // print(params);
    var ret = await execute(method, params);
    // print(ret);
    var data = ret['data'];
    if(data!=null){
      var has_next = data['has_next']=='true';
      var position_index = data['position_index'];
      var results = data['results'];
      // print(results);
      if(results!=null){
        var orders = results['publisher_order_dto'];
        if(orders is Map<String,dynamic>){
          yield orders;
        }else{
          for(var order in orders){
            yield (order as Map<String,dynamic>);
          }
          if(has_next){
            yield* _syncOneTimeOrder(startTime: startTime,endTime: endTime,
                pageNo: pageNo!=null?pageNo+1:2,pageSize: pageSize,positionIndex: position_index);
          }
        }
      }
    }else{
      throw ret['sub_msg'];
    }
  }

  Future<Duration> getTimeSpan() async{
    var timeSpan = Duration(hours: 3);
    var startTime = DateTime.now();
    var endTime = startTime.subtract(timeSpan);

    try{
      var s = _syncOneTimeOrder(startTime: formatTime(endTime),endTime: formatTime(startTime));
      await s.isEmpty;
    }catch(e){
      return Duration(minutes: 20);
    }

    return timeSpan;
  }

  void _doTask({StreamController<Map<String,dynamic>> controller,SyncProgress progress,
    TimeSpan span,List<TimeSpan> tasks,bool isLast=false,String queryType,
    ProgressCallback onProgress,FinishCallback onFinish}){
    print(span);
    var s = _syncOneTimeOrder(startTime: span.startTime,endTime: span.endTime,queryType:queryType);
    s.listen((order) {
      controller.add(order);
    }).onDone(() {
      progress.finish(span.toString());
      if(onProgress!=null){
        onProgress(progress);
      }
      if(tasks.isNotEmpty){
        var nextTask = tasks.removeAt(0);
        _doTask(controller: controller,span: nextTask,tasks: tasks,isLast: tasks.isEmpty,
            onProgress: onProgress,onFinish: onFinish,progress: progress);
      }else if(isLast==true){
        //
      }
      if(onFinish!=null && progress.isFinish){
        onFinish(progress);
        controller.close();
      }
    });
  }

  Stream<Map<String,dynamic>> syncOrders({
    DateTime startTime,DateTime endTime,String queryType,
    Duration timeSpan,int threads=1,
    ProgressCallback onProgress,FinishCallback onFinish}) {
    var controller = StreamController<Map<String,dynamic>>();

    var times = getTimeSpans(startTime: startTime,endTime: endTime,timeSpan: timeSpan);
    var progress = SyncProgress(times.length);
    var total = times.length>threads?threads:times.length;
    var tasks = times.sublist(total);
    for(var span in times.take(total)){
      _doTask(controller: controller,span: span,tasks: tasks,
          onProgress:onProgress,progress:progress,onFinish:onFinish);
    }
    return controller.stream;
  }

}

class SyncProgress {
  final int total;
  DateTime startTime;
  DateTime endTime;
  Duration duration;
  int finishTotal = 0;
  String tip;
  SyncProgress(this.total):startTime = DateTime.now();

  void finish(String span){
    finishTotal++;
    duration = DateTime.now().difference(startTime);
    tip = span;
    if(finishTotal==total){
      endTime = DateTime.now();
    }
  }

  bool get isFinish{
    return total==finishTotal;
  }

  double get finishRate{
    return finishTotal/total;
  }

  @override
  String toString() {
    return 'SyncProgress{total: $total, finishTotal: $finishTotal, startTime: $startTime, endTime: $endTime, duration: $duration}';
  }
}
