#!/usr/bin/env python
# -*- coding: utf-8 -*-

import os
from setuptools import setup , find_packages


this_directory = os.path.abspath(os.path.dirname(__file__))


with open(os.path.join(this_directory, 'README.md'), encoding='utf-8') as f:
    long_description = f.read()
    
print( find_packages())

setup(
    name='bio-moose',
    version='1.0.0',
    description='',
    long_description = long_description,
    long_description_content_type = "text/markdown",
    url='https://github.com/K2SOHIGH/OTTO',
    author='Maxime Millet',
    author_email='maxime.luc.millet@gmail.com',
    license='MIT',
    classifiers = [
        "Programming Language :: Python :: 3",
        "License :: OSI Approved :: MIT License",
        "Operating System :: OS Independent",
    ],
    install_requires=[
        #  "numpy>=1.21",
        #  "pyyaml>=6",
        #  "snakemake==7.22",
        #  "pandas>=1.5.3",
        #  "tqdm==4.64.1",
        #  "plotly==5.11.0",
        #  "python-igraph==0.10.4",         
        #  "click",
    ],
    python_requires = ">=3.9",
    packages = find_packages(),
    include_package_data=True, 
    entry_points={
    'console_scripts': [
        'moose = bin.main:entry_point',
    ],
    },
    # scripts = [script for script in glob.glob("bin/*") 
    #     if not os.path.basename(script).startswith("_") and 
    #     os.path.isfile(script)],
    # py_modules = ["bin"],
    zip_safe=False
)
