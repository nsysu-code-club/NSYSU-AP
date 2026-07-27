// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bus_time.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BusTime _$BusTimeFromJson(Map<String, dynamic> json) => BusTime(
  routeId: (json['RouteID'] as num).toInt(),
  stopId: json['StopID'] as String,
  name: json['Name'] as String,
  arrivedTime: json['ArrivedTime'] as String?,
  realArrivedTime: json['RealArrivedTime'] as String?,
  isGoBack: json['isGoBack'] as String,
  seqNo: (json['SeqNo'] as num).toInt(),
  direction: $enumDecodeNullable(_$BusDirectionEnumMap, json['Direction']),
  arrivalStatus: $enumDecodeNullable(
    _$BusArrivalStatusEnumMap,
    json['ArrivalStatus'],
  ),
  etaMinutes: (json['EtaMinutes'] as num?)?.toInt(),
  scheduledTime: json['ScheduledTime'] as String?,
);

Map<String, dynamic> _$BusTimeToJson(BusTime instance) => <String, dynamic>{
  'RouteID': instance.routeId,
  'StopID': instance.stopId,
  'Name': instance.name,
  'ArrivedTime': instance.arrivedTime,
  'RealArrivedTime': instance.realArrivedTime,
  'isGoBack': instance.isGoBack,
  'SeqNo': instance.seqNo,
  'Direction': _$BusDirectionEnumMap[instance.direction]!,
  'ArrivalStatus': _$BusArrivalStatusEnumMap[instance.arrivalStatus]!,
  'EtaMinutes': instance.etaMinutes,
  'ScheduledTime': instance.scheduledTime,
};

const _$BusDirectionEnumMap = {
  BusDirection.go: 'go',
  BusDirection.back: 'back',
};

const _$BusArrivalStatusEnumMap = {
  BusArrivalStatus.arriving: 'arriving',
  BusArrivalStatus.comingSoon: 'comingSoon',
  BusArrivalStatus.minutes: 'minutes',
  BusArrivalStatus.scheduled: 'scheduled',
  BusArrivalStatus.departed: 'departed',
  BusArrivalStatus.notOperating: 'notOperating',
};
