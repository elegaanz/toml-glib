project('toml-glib', 'vala', 'c',
        version: '0.1.0',
        license: 'MIT')

api_version = '0.1'

add_project_arguments(['-W'], language: 'c')

glib = dependency('glib-2.0')
gobject = dependency('gobject-2.0')
gio = dependency('gio-2.0')
gee = dependency('gee-0.8')

subdir('src')
subdir('tests')
