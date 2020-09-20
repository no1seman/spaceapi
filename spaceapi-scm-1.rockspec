package = 'spaceapi'
version = 'scm-1'
source = {
    url = 'git+https://github.com/no1seman/spaceapi.git',
    branch = 'master',
}

description = {
    summary = 'imple GraphQL API for managing Tarantool spaces',
    homepage = 'https://github.com/no1seman/spaceapi',
    license = 'BSDXZ',
}

dependencies = {
    'lua >= 5.1',
}

build = {
    type = 'cmake',
    variables = {
        TARANTOOL_INSTALL_LUADIR = '$(LUADIR)',
    },
}