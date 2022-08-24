/* TestTranslations -- Ensure translations are available for new timezones
   Copyright (C) 2022 Red Hat, Inc.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

import java.util.Arrays;
import java.util.Locale;
import java.util.ResourceBundle;

import sun.util.resources.LocaleData;
import sun.util.locale.provider.LocaleProviderAdapter;

public class TestTranslations {
    public static void main(String[] args) {
        for (String zone : args) {
            System.out.printf("Translations for %s\n", zone);
            for (Locale l : Locale.getAvailableLocales()) {
                ResourceBundle bundle = new LocaleData(LocaleProviderAdapter.Type.JRE).getTimeZoneNames(l);
                System.out.printf("Locale: %s, language: %s, translations: %s\n", l, l.getDisplayLanguage(), Arrays.toString(bundle.getStringArray(zone)));
            }
        }
    }
}
