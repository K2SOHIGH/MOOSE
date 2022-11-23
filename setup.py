#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from setuptools import setup , find_packages
import os
import glob

this_directory = os.path.abspath(os.path.dirname(__file__))


with open(os.path.join(this_directory, 'README.md'), encoding='utf-8') as f:
    long_description = f.read()
    

setup(
    name='mako',
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
    scripts = [script for script in glob.glob("bin/*") if not os.path.basename(script).startswith("_") ],
    py_modules = ["bin"],
    zip_safe=False
)
