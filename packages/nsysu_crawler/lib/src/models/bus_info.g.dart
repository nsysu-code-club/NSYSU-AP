// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bus_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BusInfo _$BusInfoFromJson(Map<String, dynamic> json) => BusInfo(
  carId: json['CarID'] as String?,
  busIds: (json['BusIDs'] as List<dynamic>?)?.map((e) => e as String).toList(),
  stopName: json['StopName'] as String,
  routeId: (json['RouteID'] as num).toInt(),
  name: json['Name'] as String,
  isOpenData: json['isOpenData'] as String,
  departure: json['Departure'] as String,
  destination: json['Destination'] as String,
  updateTime: json['UpdateTime'] as String?,
);

Map<String, dynamic> _$BusInfoToJson(BusInfo instance) => <String, dynamic>{
  'CarID': instance.carId,
  'BusIDs': instance.busIds,
  'StopName': instance.stopName,
  'RouteID': instance.routeId,
  'Name': instance.name,
  'isOpenData': instance.isOpenData,
  'Departure': instance.departure,
  'Destination': instance.destination,
  'UpdateTime': instance.updateTime,
};
