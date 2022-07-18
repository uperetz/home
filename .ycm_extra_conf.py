flags = [
    '-Wall',
    '-Wextra',
    '-Werror',
    '-std=c++17',
    '-x',
    'c++',
    '-I',
    'include',
]


def Settings(**kwargs):
    print('here', flags)
    return {
      'flags': flags,
    }
