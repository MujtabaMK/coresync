class UnitCategory {
  final String name;
  final List<UnitDef> units;

  const UnitCategory({required this.name, required this.units});
}

class UnitDef {
  final String name;
  final String symbol;
  // Factor to convert TO base unit. For temperature, special handling.
  final double? toBase;
  final double Function(double)? toBaseFn;
  final double Function(double)? fromBaseFn;

  const UnitDef({
    required this.name,
    required this.symbol,
    this.toBase,
    this.toBaseFn,
    this.fromBaseFn,
  });

  double convertToBase(double value) {
    if (toBaseFn != null) return toBaseFn!(value);
    return value * (toBase ?? 1);
  }

  double convertFromBase(double value) {
    if (fromBaseFn != null) return fromBaseFn!(value);
    return value / (toBase ?? 1);
  }
}

double convert(double value, UnitDef from, UnitDef to) {
  final baseValue = from.convertToBase(value);
  return to.convertFromBase(baseValue);
}

final categories = <UnitCategory>[
  // Currency – uses live rates, placeholder for tab position
  UnitCategory(name: 'Currency', units: [
    UnitDef(name: 'US Dollar', symbol: 'USD', toBase: 1),
    UnitDef(name: 'Euro', symbol: 'EUR', toBase: 1.08),
  ]),

  // Length (base: meter)
  UnitCategory(name: 'Length', units: [
    UnitDef(name: 'Kilometer', symbol: 'km', toBase: 1000),
    UnitDef(name: 'Meter', symbol: 'm', toBase: 1),
    UnitDef(name: 'Centimeter', symbol: 'cm', toBase: 0.01),
    UnitDef(name: 'Millimeter', symbol: 'mm', toBase: 0.001),
    UnitDef(name: 'Mile', symbol: 'mi', toBase: 1609.344),
    UnitDef(name: 'Yard', symbol: 'yd', toBase: 0.9144),
    UnitDef(name: 'Foot', symbol: 'ft', toBase: 0.3048),
    UnitDef(name: 'Inch', symbol: 'in', toBase: 0.0254),
    UnitDef(name: 'Nautical Mile', symbol: 'nmi', toBase: 1852),
  ]),

  // Area (base: m²)
  UnitCategory(name: 'Area', units: [
    UnitDef(name: 'Square Kilometer', symbol: 'km²', toBase: 1e6),
    UnitDef(name: 'Square Meter', symbol: 'm²', toBase: 1),
    UnitDef(name: 'Square Centimeter', symbol: 'cm²', toBase: 1e-4),
    UnitDef(name: 'Hectare', symbol: 'ha', toBase: 10000),
    UnitDef(name: 'Acre', symbol: 'ac', toBase: 4046.8564224),
    UnitDef(name: 'Square Mile', symbol: 'mi²', toBase: 2589988.110336),
    UnitDef(name: 'Square Yard', symbol: 'yd²', toBase: 0.83612736),
    UnitDef(name: 'Square Foot', symbol: 'ft²', toBase: 0.09290304),
    UnitDef(name: 'Square Inch', symbol: 'in²', toBase: 0.00064516),
  ]),

  // Volume (base: liter)
  UnitCategory(name: 'Volume', units: [
    UnitDef(name: 'Liter', symbol: 'L', toBase: 1),
    UnitDef(name: 'Milliliter', symbol: 'mL', toBase: 0.001),
    UnitDef(name: 'Cubic Meter', symbol: 'm³', toBase: 1000),
    UnitDef(name: 'Cubic Centimeter', symbol: 'cm³', toBase: 0.001),
    UnitDef(name: 'US Gallon', symbol: 'gal', toBase: 3.785411784),
    UnitDef(name: 'US Quart', symbol: 'qt', toBase: 0.946352946),
    UnitDef(name: 'US Pint', symbol: 'pt', toBase: 0.473176473),
    UnitDef(name: 'US Cup', symbol: 'cup', toBase: 0.2365882365),
    UnitDef(name: 'US Fluid Ounce', symbol: 'fl oz', toBase: 0.0295735296),
    UnitDef(name: 'Imperial Gallon', symbol: 'imp gal', toBase: 4.54609),
  ]),

  // Weight (base: kilogram)
  UnitCategory(name: 'Weight', units: [
    UnitDef(name: 'Kilogram', symbol: 'kg', toBase: 1),
    UnitDef(name: 'Gram', symbol: 'g', toBase: 0.001),
    UnitDef(name: 'Milligram', symbol: 'mg', toBase: 1e-6),
    UnitDef(name: 'Metric Ton', symbol: 't', toBase: 1000),
    UnitDef(name: 'Pound', symbol: 'lb', toBase: 0.45359237),
    UnitDef(name: 'Ounce', symbol: 'oz', toBase: 0.028349523125),
    UnitDef(name: 'Stone', symbol: 'st', toBase: 6.35029318),
  ]),

  // Temperature (special)
  UnitCategory(name: 'Temperature', units: [
    UnitDef(
      name: 'Celsius',
      symbol: '°C',
      toBaseFn: (v) => v,
      fromBaseFn: (v) => v,
    ),
    UnitDef(
      name: 'Fahrenheit',
      symbol: '°F',
      toBaseFn: (v) => (v - 32) * 5 / 9,
      fromBaseFn: (v) => v * 9 / 5 + 32,
    ),
    UnitDef(
      name: 'Kelvin',
      symbol: 'K',
      toBaseFn: (v) => v - 273.15,
      fromBaseFn: (v) => v + 273.15,
    ),
  ]),

  // Speed (base: m/s)
  UnitCategory(name: 'Speed', units: [
    UnitDef(name: 'Meter/Second', symbol: 'm/s', toBase: 1),
    UnitDef(name: 'Kilometer/Hour', symbol: 'km/h', toBase: 0.277778),
    UnitDef(name: 'Mile/Hour', symbol: 'mph', toBase: 0.44704),
    UnitDef(name: 'Knot', symbol: 'kn', toBase: 0.514444),
    UnitDef(name: 'Foot/Second', symbol: 'ft/s', toBase: 0.3048),
  ]),

  // Time (base: second)
  UnitCategory(name: 'Time', units: [
    UnitDef(name: 'Second', symbol: 's', toBase: 1),
    UnitDef(name: 'Millisecond', symbol: 'ms', toBase: 0.001),
    UnitDef(name: 'Minute', symbol: 'min', toBase: 60),
    UnitDef(name: 'Hour', symbol: 'hr', toBase: 3600),
    UnitDef(name: 'Day', symbol: 'day', toBase: 86400),
    UnitDef(name: 'Week', symbol: 'wk', toBase: 604800),
    UnitDef(name: 'Month (30d)', symbol: 'mo', toBase: 2592000),
    UnitDef(name: 'Year (365d)', symbol: 'yr', toBase: 31536000),
  ]),

  // Data (base: byte)
  UnitCategory(name: 'Data', units: [
    UnitDef(name: 'Bit', symbol: 'b', toBase: 0.125),
    UnitDef(name: 'Byte', symbol: 'B', toBase: 1),
    UnitDef(name: 'Kilobyte', symbol: 'KB', toBase: 1024),
    UnitDef(name: 'Megabyte', symbol: 'MB', toBase: 1048576),
    UnitDef(name: 'Gigabyte', symbol: 'GB', toBase: 1073741824),
    UnitDef(name: 'Terabyte', symbol: 'TB', toBase: 1099511627776),
  ]),

  // Energy (base: joule)
  UnitCategory(name: 'Energy', units: [
    UnitDef(name: 'Joule', symbol: 'J', toBase: 1),
    UnitDef(name: 'Kilojoule', symbol: 'kJ', toBase: 1000),
    UnitDef(name: 'Calorie', symbol: 'cal', toBase: 4.184),
    UnitDef(name: 'Kilocalorie', symbol: 'kcal', toBase: 4184),
    UnitDef(name: 'Watt Hour', symbol: 'Wh', toBase: 3600),
    UnitDef(name: 'Kilowatt Hour', symbol: 'kWh', toBase: 3600000),
    UnitDef(name: 'BTU', symbol: 'BTU', toBase: 1055.06),
  ]),

  // Pressure (base: pascal)
  UnitCategory(name: 'Pressure', units: [
    UnitDef(name: 'Pascal', symbol: 'Pa', toBase: 1),
    UnitDef(name: 'Kilopascal', symbol: 'kPa', toBase: 1000),
    UnitDef(name: 'Bar', symbol: 'bar', toBase: 100000),
    UnitDef(name: 'Atmosphere', symbol: 'atm', toBase: 101325),
    UnitDef(name: 'PSI', symbol: 'psi', toBase: 6894.757),
    UnitDef(name: 'Torr', symbol: 'Torr', toBase: 133.322),
  ]),

  // Power (base: watt)
  UnitCategory(name: 'Power', units: [
    UnitDef(name: 'Watt', symbol: 'W', toBase: 1),
    UnitDef(name: 'Kilowatt', symbol: 'kW', toBase: 1000),
    UnitDef(name: 'Megawatt', symbol: 'MW', toBase: 1e6),
    UnitDef(name: 'Horsepower', symbol: 'hp', toBase: 745.7),
    UnitDef(name: 'BTU/Hour', symbol: 'BTU/h', toBase: 0.293071),
  ]),

  // Angle (base: degree)
  UnitCategory(name: 'Angle', units: [
    UnitDef(name: 'Degree', symbol: '°', toBase: 1),
    UnitDef(name: 'Radian', symbol: 'rad', toBase: 57.2957795131),
    UnitDef(name: 'Gradian', symbol: 'gon', toBase: 0.9),
    UnitDef(name: 'Arcminute', symbol: "'", toBase: 1 / 60),
    UnitDef(name: 'Arcsecond', symbol: '"', toBase: 1 / 3600),
    UnitDef(name: 'Revolution', symbol: 'rev', toBase: 360),
  ]),

  // Fuel (base: km/L)
  UnitCategory(name: 'Fuel', units: [
    UnitDef(name: 'Km per Liter', symbol: 'km/L', toBase: 1),
    UnitDef(name: 'Miles per Gallon (US)', symbol: 'mpg', toBase: 0.425144),
    UnitDef(name: 'Miles per Gallon (Imp)', symbol: 'mpg(imp)', toBase: 0.354006),
    UnitDef(
      name: 'Liters per 100km',
      symbol: 'L/100km',
      toBaseFn: (v) => v == 0 ? 0 : 100 / v,
      fromBaseFn: (v) => v == 0 ? 0 : 100 / v,
    ),
  ]),

  // Force (base: newton)
  UnitCategory(name: 'Force', units: [
    UnitDef(name: 'Newton', symbol: 'N', toBase: 1),
    UnitDef(name: 'Kilonewton', symbol: 'kN', toBase: 1000),
    UnitDef(name: 'Dyne', symbol: 'dyn', toBase: 1e-5),
    UnitDef(name: 'Pound-Force', symbol: 'lbf', toBase: 4.44822),
    UnitDef(name: 'Kilogram-Force', symbol: 'kgf', toBase: 9.80665),
  ]),
];
