"""Disposable package/metadata rejection tests; no Steam or game invocation."""
from pathlib import Path
import sys
import tempfile
import unittest
import warnings
import zipfile
sys.path.insert(0, str(Path(__file__).resolve().parents[1]/'scripts'))
from prepare_workshop import canonical, validate_zip, vdf, NOTICE


class WorkshopPackage(unittest.TestCase):
    def setUp(self):
        folder = tempfile.TemporaryDirectory(); self.addCleanup(folder.cleanup)
        self.root = Path(folder.name)
        self.archive = self.root/'test.zip'

    def write_zip(self, entries):
        with warnings.catch_warnings():
            warnings.simplefilter('ignore', UserWarning)
            with zipfile.ZipFile(self.archive, 'w') as archive:
                for name, raw in entries: archive.writestr(name, raw)

    def test_source_crc_and_exact_inventory(self):
        expected = {'Contents/mods/B47ANCEDKnowledgeAndWisdom/42/mod.info': b'id=B47ANCEDKnowledgeAndWisdom\n'}
        self.write_zip(expected.items()); validate_zip(self.archive, expected)
        for entries in ([('unexpected', b'x')], [(next(iter(expected)), b'wrong')], []):
            self.write_zip(entries)
            with self.assertRaises(ValueError): validate_zip(self.archive, expected)
        self.write_zip(expected.items())
        data = bytearray(self.archive.read_bytes()); pos = data.index(b'id=B47ANCEDKnowledgeAndWisdom'); data[pos] ^= 1
        self.archive.write_bytes(data)
        with self.assertRaises((ValueError, zipfile.BadZipFile)): validate_zip(self.archive, expected)

    def test_duplicate_case_and_path_traversal_refuse(self):
        for names in (['a', 'a'], ['A', 'a'], ['../outside'], ['/absolute'], ['C:/outside'], ['a\\b'], ['a/./b']):
            entries = [(name, b'x') for name in names]; self.write_zip(entries)
            with self.assertRaises(ValueError): validate_zip(self.archive, dict(entries))

    def test_test_label_source_and_real_paragraphs(self):
        description = NOTICE+'\n\n[url=https://github.com/B47ANCE/B47ANCEDKnowledgeAndWisdom]Source[/url]'
        note = NOTICE+'\n\nHuman testing remains required.'
        for name, value in [('WORKSHOP_ID.txt', '3792566496'), ('WORKSHOP_DESCRIPTION.txt', description),
                            ('WORKSHOP_CHANGE_NOTE.txt', note), ('workshop.txt', '\n'.join('description='+s for s in description.splitlines()))]:
            (self.root/name).write_bytes(value.encode())
        self.assertEqual(canonical(self.root), (description, note))
        for invalid in (description.replace(NOTICE, 'untested'), description+'\\nserialized', 'x'*8000):
            (self.root/'WORKSHOP_DESCRIPTION.txt').write_bytes(invalid.encode())
            with self.assertRaises(ValueError): canonical(self.root)
        (self.root/'WORKSHOP_ID.txt').write_bytes(b'0')
        with self.assertRaises(ValueError): canonical(self.root)

    def test_vdf_preserves_item_identity_and_visibility(self):
        text = vdf(self.root, 'line one\n\nline "two"', NOTICE)
        self.assertIn('"appid" "108600"', text)
        self.assertIn('"publishedfileid" "3792566496"', text)
        self.assertNotIn('"visibility"', text)
        self.assertNotIn('"title"', text)
        self.assertNotIn('"tags"', text)
        self.assertIn('line one\n\nline \\"two\\"', text)


if __name__ == '__main__':
    unittest.main()
