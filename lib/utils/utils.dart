String toArabicNumber(int number) {
  const Map<String, String> arabicNumbers = {
    '0': '٠',
    '1': '١',
    '2': '٢',
    '3': '٣',
    '4': '٤',
    '5': '٥',
    '6': '٦',
    '7': '٧',
    '8': '٨',
    '9': '٩',
  };

  return number
      .toString()
      .split('')
      .map((digit) => arabicNumbers[digit] ?? digit)
      .join('');
}

int showPageNumber(int pageNumber, bool isDoublePaged) {
  return isDoublePaged ? pageNumber = (pageNumber * 2).ceil() : pageNumber;
}

String latToString(double lat,
    {bool showMinutes = false, bool showSeconds = false}) {
  // Convert the latitude and longitude to degrees and minutes
  double degrees = lat;
  double minutes = (lat - degrees) * 60;
  double seconds = (minutes - minutes.toInt()) * 60;

  // Convert the degrees, minutes, and seconds to strings
  String degreesStr = degrees.toStringAsFixed(1);
  String minutesStr = minutes.toStringAsFixed(1);
  String secondsStr = seconds.toStringAsFixed(1);

  // Return the string representation of the latitude and longitude
  return '$degreesStr°${showMinutes ? " $minutesStr\'" : ''}${showSeconds ? " $secondsStr\"" : ''} N';
}

String lngToString(double lng,
    {bool showMinutes = false, bool showSeconds = false}) {
  // Convert the latitude and longitude to degrees and minutes
  double degrees = lng;
  double minutes = (lng - degrees) * 60;
  double seconds = (minutes - minutes.toInt()) * 60;

  // Convert the degrees, minutes, and seconds to strings
  String degreesStr = degrees.toStringAsFixed(1);
  String minutesStr = minutes.toStringAsFixed(1);
  String secondsStr = seconds.toStringAsFixed(1);

  // Return the string representation of the latitude and longitude
  return '$degreesStr°${showMinutes ? " $minutesStr\'" : ''}${showSeconds ? " $secondsStr\"" : ''} E';
}
