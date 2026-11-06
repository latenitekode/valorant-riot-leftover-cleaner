"""Basic static guardrails. Run: python -m unittest discover -s tests -v"""
import pathlib
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]
SCANNER = (ROOT / 'Check_Riot_Leftovers.bat').read_text(encoding='utf-8')
CLEANER = (ROOT / 'Delete_Riot_Leftovers.bat').read_text(encoding='utf-8')


class SafetyChecks(unittest.TestCase):
    def test_scanner_does_not_delete_files(self):
        for cmd in ('Remove-Item', 'rmdir ', 'del /', 'sc delete', 'Stop-Service'):
            self.assertNotIn(cmd.lower(), SCANNER.lower())

    def test_cleaner_requires_explicit_confirmation(self):
        self.assertIn("$confirmation -cne 'DELETE'", CLEANER)
        self.assertIn('Remove-Item -LiteralPath $path -Recurse -Force', CLEANER)

    def test_cleaner_allowlist_contains_only_five_directories(self):
        self.assertEqual(CLEANER.count('Title = '), 5)
        self.assertIn('C:\\Riot Games\\VALORANT', CLEANER)
        self.assertIn('C:\\Riot Games\\Riot Client', CLEANER)
        self.assertNotIn("Title = 'Riot Vanguard'", CLEANER)

    def test_reparse_point_guard(self):
        self.assertIn('Is-ReparsePoint', CLEANER)
        self.assertIn('Is-SafeFolder', CLEANER)
        self.assertIn('if (Is-SafeFolder $path)', CLEANER)

    def test_parent_junction_protection(self):
        self.assertIn('$ancestor = $item', CLEANER)
        self.assertIn('while ($null -ne $ancestor)', CLEANER)
        self.assertIn('$ancestor = $ancestor.Parent', CLEANER)
        self.assertIn('if (Is-ReparsePoint $ancestor)', CLEANER)

    def test_vanguard_uses_windows_uninstaller(self):
        self.assertIn('Windows Settings > Apps > Installed apps', CLEANER)
        self.assertNotIn("Path = (Join-Path $env:ProgramFiles 'Riot Vanguard')", CLEANER)

    def test_batch_wrapper_survives_and_has_marker(self):
        for script in (SCANNER, CLEANER):
            self.assertIn('PRESS ANY KEY TO CLOSE THIS WINDOW.', script)
            self.assertEqual(script.count('# POWERSHELL_START'), 2)  # invocation + delimiter
            self.assertLess(script.index('exit /b'), script.rindex('# POWERSHELL_START'))

    def test_all_selection_does_not_include_programdata(self):
        self.assertIn("if ($selection -ieq 'ALL') { $ids = @(1,2,3,4) }", CLEANER)

    def test_no_forceful_vanguard_or_registry_changes(self):
        for cmd in ('sc delete', 'reg delete', 'Stop-Service', 'Remove-Service', 'taskkill'):
            self.assertNotIn(cmd.lower(), CLEANER.lower())


if __name__ == '__main__':
    unittest.main()
