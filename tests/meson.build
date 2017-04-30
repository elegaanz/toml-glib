test_sources = files('lexer.vala',
                     'parser.vala',
                     'toml-glib.vala',
                     'writer.vala')

test('tests',
     executable('tests', test_sources,
                dependencies: [glib, gobject, gio, gee, toml]),
     env: ['G_TEST_SRCDIR=' + meson.current_source_dir()]
)
