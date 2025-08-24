// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Savdo-UZ';

  @override
  String get employeeAdd => 'Добавить сотрудника';

  @override
  String get employeeEdit => 'Редактировать сотрудника';

  @override
  String get delete => 'Удалить';

  @override
  String get cancel => 'Отмена';

  @override
  String get save => 'Сохранить';

  @override
  String get name => 'Имя';

  @override
  String get position => 'Должность';

  @override
  String get phone => 'Телефон';

  @override
  String get email => 'Email (необязательно)';

  @override
  String get login => 'Логин';

  @override
  String get password => 'Пароль';

  @override
  String get faceScan => 'Сканирование лица';

  @override
  String get validationName => 'Введите имя';

  @override
  String get validationPosition => 'Введите должность';

  @override
  String get validationPhone => 'Введите номер телефона';

  @override
  String get validationPhoneFormat => 'Введите правильный номер телефона (998 XX XXX XX XX)';

  @override
  String get validationEmailFormat => 'Введите правильный email (например: user@mail.com)';

  @override
  String get validationLogin => 'Введите логин';

  @override
  String get validationPassword => 'Введите пароль';
}
