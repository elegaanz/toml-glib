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

toml_lib = library('toml-glib', sources,
                   dependencies: toml_glib_deps,
                   vala_header: 'toml.h',
                   install: true,
                   install_dir: [true, true, true])

install_data(
    'toml-glib.deps',
    install_dir: join_paths(get_option('datadir'), 'vala', 'vapi')
)

toml = declare_dependency(
    dependencies: toml_glib_deps,
    include_directories: include_directories('.'),
    link_with: toml_lib
)

toml_lib_pc = pkgconfig.generate(
    toml_lib,
    name: 'toml-glib',
    requires: toml_glib_deps,
    subdirs: ['toml-glib'],
    description: 'A small library to parse TOML',
    version: meson.project_version(),
    url: 'https://github.com/elegaanz/toml-glib',
)
