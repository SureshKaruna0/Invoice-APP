String numberToIndianWords(double number) {
  if (number == 0) return 'Rupees Zero Only';

  final units = [
    '', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine',
    'Ten', 'Eleven', 'Twelve', 'Thirteen', 'Fourteen', 'Fifteen', 'Sixteen',
    'Seventeen', 'Eighteen', 'Nineteen'
  ];

  final tens = [
    '', '', 'Twenty', 'Thirty', 'Forty', 'Fifty', 'Sixty', 'Seventy', 'Eighty', 'Ninety'
  ];

  String convertBelowThousand(int n) {
    if (n == 0) return '';
    if (n < 20) return units[n];
    if (n < 100) {
      return tens[n ~/ 10] + (n % 10 != 0 ? ' ${units[n % 10]}' : '');
    }
    return '${units[n ~/ 100]} Hundred${n % 100 != 0 ? ' and ${convertBelowThousand(n % 100)}' : ''}';
  }

  int intPart = number.truncate();
  int decimalPart = ((number - intPart) * 100).round();

  if (intPart == 0 && decimalPart > 0) {
    return 'Paise ${convertBelowThousand(decimalPart)} Only';
  }

  String result = '';

  int crore = intPart ~/ 10000000;
  intPart %= 10000000;

  int lakh = intPart ~/ 100000;
  intPart %= 100000;

  int thousand = intPart ~/ 1000;
  int remainder = intPart % 1000;

  if (crore > 0) {
    result += '${convertBelowThousand(crore)} Crore ';
  }
  if (lakh > 0) {
    result += '${convertBelowThousand(lakh)} Lakh ';
  }
  if (thousand > 0) {
    result += '${convertBelowThousand(thousand)} Thousand ';
  }
  if (remainder > 0) {
    result += convertBelowThousand(remainder);
  }

  result = 'Rupees ${result.trim()}';

  if (decimalPart > 0) {
    result += ' and ${convertBelowThousand(decimalPart)} Paise';
  }

  return '$result Only';
}

