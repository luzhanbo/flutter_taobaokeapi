String formatTime(DateTime dt){
  var pos = dt.toString().indexOf('.');
  return dt.toString().substring(0,pos);
}

DateTime lastMonthFirstDay(){
  var now = DateTime.now();
  var year = now.year;
  var month = now.month-1;
  if(month==0){
    year--;
    month = 12;
  }
  return DateTime(year,month,1);
}

class TimeSpan{
  final String startTime;
  final String endTime;
  TimeSpan(this.startTime,this.endTime);
  @override
  String toString() {
    return '${startTime}-${endTime}';
  }
}

List<TimeSpan> getTimeSpans({DateTime startTime,DateTime endTime,Duration timeSpan}){
  var time = startTime;
  var times = <TimeSpan>[];
  do{
    var et = formatTime(time);
    time = time.subtract(timeSpan);
    if(time.isBefore(endTime)){
      time = endTime;
    }
    var st = formatTime(time);
    var tSpan = TimeSpan(st, et);
    times.add(tSpan);
  }while(time.isAfter(endTime));
  return times;
}
