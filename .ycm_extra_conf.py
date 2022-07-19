"""CPP flags to be used with YouCompleteMe Vim plugin."""
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


def Settings(**_kwargs):
  return {
      'flags': flags,
  }
