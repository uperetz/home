flags = [
        '-Wall',
        '-Wextra',
        '-Werror',
        # '-x',
        # 'c++',
        # '-std=c++17',
        '-x',
        'c',
        '-std=c99',
        '-I',
        'include',
        ]


def Settings(**kwargs):
    print('here', flags)
    return {
            'flags': flags,
            }
