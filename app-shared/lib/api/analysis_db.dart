import 'package:flutter/cupertino.dart';
import 'package:sqflite/sqflite.dart';
import 'iana.dart';
import 'orchid_api.dart';

class AnalysisDb {
  static AnalysisDb _shared = AnalysisDb._init();
  Database _db;
  static final String unknown = "???"; // Localize

  AnalysisDb._init();

  Future _getDb() async {
    if (_db != null && _db.isOpen) {
      return _db;
    }
    String dbPath = (await OrchidAPI().groupContainerPath()) + '/analysis.db';
    debugPrint("analysis db path: $dbPath");
    try {
      _db = await openDatabase(dbPath, readOnly: true);
    } catch (err) {
      debugPrint("Error opening analysis db: $err");
      return null;
    }
    debugPrint("analysis db result: $_db");
    return _db;
  }

  Future<List<FlowEntry>> query({String textFilter}) async {
    var db = await _getDb();
    if (db == null) {
      return List();
    }
    var filter =
        textFilter.replaceAll(new RegExp(r'[^\w\s]+'), ''); // Safe query string
    var queryClaus = (textFilter == null || textFilter.isEmpty)
        ? ""
        : " WHERE hostname LIKE '%${filter}%'";
    var orderBy = ' ORDER BY "start" DESC';
    var limitClaus = ' LIMIT 1000'; // ?
    List<Map> list = await db.rawQuery(
        'SELECT rowid, * FROM flow' + queryClaus + orderBy + limitClaus);
    return list.map((row) {
      return FlowEntry(
          rowId: row['rowid'],
          start: fromJulianDate(row['start']),
          l4_protocol: _fromProtocol(row['l4_protocol']),
          protocol: row['protocol'],
          src_addr: _fromAddr(row['src_addr']),
          src_port: row['src_port'],
          dst_addr: _fromAddr(row['dst_addr']),
          dst_port: row['dst_port'],
          hostname: row['hostname']);
    }).toList(growable: false);
  }

  String _fromAddr(int addr) {
    var a1 = addr >> 24;
    var a2 = addr >> 16 & 255;
    var a3 = addr >> 8 & 255;
    var a4 = addr & 255;
    return "$a1.$a2.$a3.$a4";
  }

  String _fromProtocol(int number) {
    if (number == null) {
      return unknown;
    }
    return IANA.protocol[number] ?? unknown;
  }

  factory AnalysisDb() {
    return _shared;
  }

  void dispose() {
    _db.close();
  }

  // https://github.com/zulfahmi93/dart-libcalendar/blob/master/lib/src/calendar_converter.dart
  static DateTime fromJulianDate(double jd) {
    final int _kMicrosecondsInOneDay = 86400000000;
    final int us = (jd * _kMicrosecondsInOneDay).toInt();
    final Duration duration = new Duration(microseconds: us);
    final DateTime _kJulianEpoch = new DateTime.utc(-4713, 11, 24, 12, 0);
    return _kJulianEpoch.add(duration);
  }
}

class FlowEntry {
  final int rowId;
  final DateTime start;
  final String l4_protocol;
  final String protocol;
  final String src_addr;
  final int src_port;
  final String dst_addr;
  final int dst_port;
  final String hostname;

  FlowEntry(
      {this.rowId,
      this.start,
      this.l4_protocol,
      this.protocol,
      this.src_addr,
      this.src_port,
      this.dst_addr,
      this.dst_port,
      this.hostname});
}
