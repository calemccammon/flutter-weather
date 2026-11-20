/// The two systems of units the app can show a forecast in.
enum Units {
  metric,
  imperial;

  /// The United States, Liberia and Myanmar use Fahrenheit and miles.
  factory Units.forCountry(String? countryCode) =>
      const {'US', 'LR', 'MM'}.contains(countryCode) ? imperial : metric;
}
