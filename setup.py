from setuptools import setup, find_packages

readme = open('./pyREADME.md', 'r')

setup(
    name='py-mimic-fhir',
    version='0.9.2',
    author='Alex Bennett',
    author_email='alexmbennett2@gmail.com',
    packages=find_packages(exclude=['tests', 'tests.*']),
    description='A package to help convert MIMIC to FHIR',
    long_description=readme.read(),
    long_description_content_type="text/markdown",
    url='https://github.com/kind-lab/mimic-fhir',
    install_requires=['pandas', 'numpy', 'requests', 'psycopg2>=2.86'],
    python_requires=">=3.8",
)
