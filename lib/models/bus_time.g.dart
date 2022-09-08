// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bus_time.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BusTime _$BusTimeFromJson(Map<String, dynamic> json) => BusTime(
      routeId: json['RouteID'] as int,
      stopId: json['StopID'] as String,
      name: json['Name'] as String,
      arrivedTime: json['ArrivedTime'] as String?,
      realArrivedTime: json['RealArrivedTime'] as String?,
      isGoBack: json['isGoBack'] as String,
      seqNo: json['SeqNo'] as int,
    );

Map<String, dynamic> _$BusTimeToJson(BusTime instance) => <String, dynamic>{
      'RouteID': instance.routeId,
      'StopID': instance.stopId,
      'Name': instance.name,
      'ArrivedTime': instance.arrivedTime,
      'RealArrivedTime': instance.realArrivedTime,
      'isGoBack': instance.isGoBack,
      'SeqNo': instance.seqNo,
    };
