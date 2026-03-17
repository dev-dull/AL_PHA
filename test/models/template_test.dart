import 'package:flutter_test/flutter_test.dart';
import 'package:alpha/features/template/data/templates.dart';

void main() {
  group('Board Templates', () {
    test('should have 5 default templates', () {
      expect(defaultTemplates.length, 5);
    });

    test('weekly template should have 7 columns', () {
      final weekly =
          defaultTemplates.firstWhere((t) => t.id == 'weekly');
      expect(weekly.columns.length, 7);
      expect(weekly.columns.first.label, 'Mon');
      expect(weekly.columns.last.label, 'Sun');
    });

    test('monthly template should have 31 columns', () {
      final monthly =
          defaultTemplates.firstWhere((t) => t.id == 'monthly');
      expect(monthly.columns.length, 31);
      expect(monthly.columns.first.label, '1');
      expect(monthly.columns.last.label, '31');
    });

    test('GTD template should have 7 context columns', () {
      final gtd =
          defaultTemplates.firstWhere((t) => t.id == 'gtd-contexts');
      expect(gtd.columns.length, 7);
      expect(gtd.columns.first.label, '@Phone');
    });

    test('daily hourly template should cover 6AM to 10PM', () {
      final daily =
          defaultTemplates.firstWhere((t) => t.id == 'daily-hourly');
      expect(daily.columns.length, 17);
      expect(daily.columns.first.label, '6AM');
      expect(daily.columns.last.label, '10PM');
    });

    test('project tracker should have 4 columns', () {
      final project =
          defaultTemplates.firstWhere((t) => t.id == 'project-tracker');
      expect(project.columns.length, 4);
    });

    test('all templates should have unique IDs', () {
      final ids = defaultTemplates.map((t) => t.id).toSet();
      expect(ids.length, defaultTemplates.length);
    });

    test('all template columns should have sequential positions', () {
      for (final template in defaultTemplates) {
        for (var i = 0; i < template.columns.length; i++) {
          expect(template.columns[i].position, i);
        }
      }
    });
  });
}
