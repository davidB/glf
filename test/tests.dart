import 'package:unittest/unittest.dart';
import 'package:unittest/html_enhanced_config.dart';

import '../../glf/test/meshdef_test.dart' as meshdef_test;
main() {
  useHtmlEnhancedConfiguration();
  group('meshdef_test', meshdef_test.main);
  print('tests complete.');
}

