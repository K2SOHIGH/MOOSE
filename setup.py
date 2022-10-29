#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from setuptools import setup , find_packages
from os import path


this_directory = path.abspath(path.dirname(__file__))


with open(path.join(this_directory, 'README.md'), encoding='utf-8') as f:
    long_description = f.read()

setup(
    name='mgw',
    version='0.1',
    description="""
        metagenomic workflow performing reads QC , reads assemblies and assemblies QC    
        """,
    url='',
    author='Maxime Millet',
    author_email='maxime.luc.millet@gmail.com',
    license='MIT',
    packages=find_packages(),
    # install_requires=[    
    #     "click",
    #     "snakemake",
    #     "numpy==1.22.4",
    #     "pyyaml==6.0",
    #     "pandas",        
    # ],    
    include_package_data=True,
    entry_points = {
        'console_scripts': ['mgw = metagenomics_workflow:cli'],
    },
    zip_safe=False
)
