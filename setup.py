from setuptools import setup

setup(
    name='py_mimimc_fhir',
    version='0.1.0',
    author='Alex Bennett',
    packages=['py_mimic_fhir'],
    description='A package to help convert mimic to fhir',
    install_requires=["pandas"]
)