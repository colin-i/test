
#if there is the problam like in info.md with python10:
#	apt download audapa
#	sudo dpkg --ignore-depends=python3-pyaudio -i audapa.......deb

pkname='audapa'

import pathlib
HERE = pathlib.Path(__file__).parent
README = (HERE / "info.md").read_text()

from setuptools import setup
setup(name=pkname,
	version='1.0.1',
	packages=[pkname],
	#optionals
	python_requires='>=3.8',
	install_requires=[
		"pycairo>=1.20.0","PyGObject>=3.40",
		"appdirs>=1.4.3",
		"PyAudio>=0.2.11"],
	description='Audio wave file manipulator',
	long_description=README,
	long_description_content_type="text/markdown",
	url='https://github.com/colin-i/audapa',
	author='colin-i',
	author_email='costin.botescu@gmail.com',
	license='MIT',
	entry_points = {
		'console_scripts': [pkname+'='+pkname+'.main:main']
	}
)
