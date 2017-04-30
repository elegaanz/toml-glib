sources = files('category.vala',
                'configuration.vala',
                'element.vala',
                'evaluator.vala',
                'grammar.vala',
                'lexer.vala',
                'parser.vala',
                'serializer.vala',
                'token.vala',
                'toml.vala',
                'writer.vala')

gir_file = 'Toml-' + api_version + '.gir'

toml_lib = library('toml-glib' + api_version, sources,
                   dependencies: [glib, gobject, gio, gee],
                   vala_header: 'toml.h',
                   install: true,
                   install_dir: [true, true, true])

toml = declare_dependency(include_directories: include_directories('.'),
                          link_with: toml_lib)
