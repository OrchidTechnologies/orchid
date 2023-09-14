/// Parse queries for the analysis db.
class QueryParser {
  static const String UNSAFE_CHARS = r'[^\w\s-.]+';
  static const String PROTOCOL = r'^prot:([\w]+)$';

  String queryText;

  QueryParser(this.queryText);

  String _safe(String text) {
    return text.replaceAll(RegExp(UNSAFE_CHARS), '');
  }

  String _not(bool not, String text) {
    return not ? 'NOT $text' : text;
  }

  String _like(bool not, String text) {
    return _not(not, 'LIKE ') + "'%${_safe(text)}%'";
  }

  String _colLike(bool not, String colName, String text) {
    return "$colName ${_like(not, text)}";
  }

  String _hostnameOrDestIP() {
    var dstIp = _ipColToString('dst_addr');
    return "COALESCE(hostname, $dstIp) hostname_or_dst_addr";
  }

  String _hostnameOrDestIPLike(bool not, String text) {
    return _colLike(not, 'hostname_or_dst_addr', text);
  }

  String _protocolLike(bool not, String text) {
    return _colLike(not, 'protocol', text);
  }

  String _whereAnd(Iterable<String> clauses) {
    if (clauses.length == 0) {
      return "";
    }
    return " WHERE (" + clauses.join(" AND ") + ")";
  }

  /// Convert int ip to string (ntoa).
  String _ipColToString(String colName) {
    return "(($colName >> 24) || '.' || (($colName >> 16) & 255) || '.' || (($colName >> 8) & 255) || '.' || ($colName & 255))";
  }

  String? _parseTerm(String text) {
    bool not = false;
    if (text.startsWith('-')) {
      if (text == '-') {
        // Ignore a lone leading '-'
        return null;
      }
      text = text.substring(1);
      not = true;
    }
    var match = RegExp(PROTOCOL).firstMatch(text);
    if (match != null) {
      return _protocolLike(not, match.group(1) ?? '');
    }
    return _hostnameOrDestIPLike(not, text);
  }

  String parse() {
    String restrictions = "";
    if (queryText.trim().isNotEmpty) {
      var words = queryText.trim().split(RegExp(r'\s+'));
      Iterable<String> clauses = words.map(_parseTerm).whereType<String>();
      restrictions = _whereAnd(clauses);
    }
    var orderBy = ' ORDER BY "start" DESC';
    var limit = ' LIMIT 1000'; // ?
    var hostnameOrDestIp = _hostnameOrDestIP();
    return "SELECT id, $hostnameOrDestIp, * FROM flow" +
        restrictions +
        orderBy +
        limit;
  }
}
