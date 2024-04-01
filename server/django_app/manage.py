import pathlib
import sys

import django.conf


file = pathlib.Path(__file__).resolve()
root = file.parents[1]
sys.path.append(str(root))

INSTALLED_APPS = [
    'django_app'
]

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': f'{root}/django_app/db.sqlite3'
    }
}

django.conf.settings.configure(
    INSTALLED_APPS=INSTALLED_APPS,
    DATABASES=DATABASES,
    DEFAULT_AUTO_FIELD='django.db.models.AutoField'
)

django.setup()

if __name__ == '__main__':
    from django.core.management import execute_from_command_line
    execute_from_command_line(sys.argv)