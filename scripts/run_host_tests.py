"""Run isolated Lua host regressions through Lupa; never starts Project Zomboid."""
import argparse
import os
from pathlib import Path
from lupa.lua51 import LuaRuntime

ROOT = Path(__file__).resolve().parents[1]
BASE = Path('src/B47ANCEDKnowledgeAndWisdom/42/media')
ARGUMENTS = {
    'test_origin_knowledge.lua': [BASE / 'lua/shared/B47ANCEDKnowledgeAndWisdom/OriginKnowledge.lua'],
    'test_realm_load_graph.lua': [BASE / 'lua/client/B47ANCEDKnowledgeAndWisdom/Load.lua', BASE / 'lua/server/B47ANCEDKnowledgeAndWisdom/Load.lua'],
    'test_test_harness.lua': [BASE / 'scripts/B47ANCEDKnowledgeAndWisdom_TestItems.txt'],
}


def main():
    os.chdir(ROOT)
    failures = []
    tests = sorted((ROOT / 'tests').glob('test_*.lua'))
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--test', action='append', choices=[p.name for p in tests])
    selected = parser.parse_args().test
    if selected:
        tests = [p for p in tests if p.name in selected]
    for test in tests:
        runtime = LuaRuntime(unpack_returned_tuples=True)
        paths = ';'.join((ROOT / BASE / 'lua' / realm / '?.lua').as_posix() for realm in ('shared', 'client', 'server'))
        runtime.globals().package.path = paths + ';' + runtime.globals().package.path
        runtime.globals().arg = runtime.table_from([p.as_posix() for p in ARGUMENTS.get(test.name, [])])
        output = []
        runtime.globals().print = lambda *values: output.append(' '.join(map(str, values)))
        try:
            runtime.execute(test.read_text(encoding='utf-8-sig'), name='@' + test.as_posix())
            print('PASS:', test.name)
        except Exception as exc:
            failures.append(test.name)
            print('FAIL:', test.name, str(exc))
            print('\n'.join(output[-5:]))
    print(f'Lua 5.1 host regressions: {len(tests) - len(failures)}/{len(tests)} passed. PZ runtime NOT TESTED.')
    raise SystemExit(bool(failures))


if __name__ == '__main__':
    main()
