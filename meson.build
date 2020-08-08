project('toml-glib', 'vala', 'c',
        version: '0.1.0',
        license: 'GPL-3.0')

pkgconfig = import('pkgconfig')

api_version = '0.1'

add_project_arguments(['-W'], language: 'c')

toml_glib_deps = [
    dependency('glib-2.0'),
    dependency('gobject-2.0'),
    dependency('gio-2.0'),
    dependency('gee-0.8'),
]

subdir('src')
subdir('tests')
