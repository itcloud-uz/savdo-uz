// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Savdo-UZ';

  @override
  String get employeeAdd => 'Add Employee';

  @override
  String get employeeEdit => 'Edit Employee';

  @override
  String get delete => 'Delete';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get name => 'Name';

  @override
  String get position => 'Position';

  @override
  String get phone => 'Phone';

  @override
  String get email => 'Email (optional)';

  @override
  String get login => 'Login';

  @override
  String get password => 'Password';

  @override
  String get faceScan => 'Face Scan';

  @override
  String get validationName => 'Please enter name';

  @override
  String get validationPosition => 'Please enter position';

  @override
  String get validationPhone => 'Please enter phone number';

  @override
  String get validationPhoneFormat => 'Enter a valid phone number (998 XX XXX XX XX)';

  @override
  String get validationEmailFormat => 'Enter a valid email (e.g. user@mail.com)';

  @override
  String get validationLogin => 'Please enter login';

  @override
  String get validationPassword => 'Please enter password';
}
