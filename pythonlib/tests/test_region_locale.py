import unittest
from unittest.mock import patch

from camoufox.locales import SELECTOR


class RegionLocaleTests(unittest.TestCase):
    def test_region_locale_is_always_american_english(self):
        with patch(
            "camoufox.locales.np.random.choice",
            side_effect=AssertionError("Region locale selection must not sample a random language"),
        ):
            for region in ("US", "ES", "JP"):
                with self.subTest(region=region):
                    self.assertEqual(SELECTOR.from_region(region).as_string, "en-US")
