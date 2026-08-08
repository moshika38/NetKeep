class IspConfig {
  final String name;
  final String url;
  final bool isRecommended;

  const IspConfig({
    required this.name,
    required this.url,
    this.isRecommended = false,
  });
}

const List<IspConfig> supportedIsps = [
  IspConfig(
    name: 'Hutch',
    url: 'https://oneapp.hutch.lk',
    isRecommended: true,
  ),
  IspConfig(name: 'Dialog', url: 'https://selfcare.dialog.lk'),
  IspConfig(name: 'Mobitel', url: 'https://mas.mobitel.lk'),
  IspConfig(name: 'Airtel', url: 'https://my.airtel.lk'),
];

const String defaultIspUrl = 'https://oneapp.hutch.lk';
