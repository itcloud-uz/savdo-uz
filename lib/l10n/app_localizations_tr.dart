// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'Savdo-UZ';

  @override
  String get employeeAdd => 'Çalışan Ekle';

  @override
  String get employeeEdit => 'Çalışanı Düzenle';

  @override
  String get delete => 'Sil';

  @override
  String get cancel => 'İptal';

  @override
  String get save => 'Kaydet';

  @override
  String get name => 'Adı Soyadı';

  @override
  String get position => 'Pozisyonu';

  @override
  String get phone => 'Telefon Numarası';

  @override
  String get email => 'Email (isteğe bağlı)';

  @override
  String get login => 'Giriş';

  @override
  String get password => 'Şifre';

  @override
  String get faceScan => 'Yüz Tarama';

  @override
  String get validationName => 'Adı girin';

  @override
  String get validationPosition => 'Pozisyonu girin';

  @override
  String get validationPhone => 'Telefon numarasını girin';

  @override
  String get validationPhoneFormat => 'Geçerli bir telefon numarası girin (998 XX XXX XX XX)';

  @override
  String get validationEmailFormat => 'Geçerli bir email girin (ör: user@mail.com)';

  @override
  String get validationLogin => 'Giriş girin';

  @override
  String get validationPassword => 'Şifre girin';
}
