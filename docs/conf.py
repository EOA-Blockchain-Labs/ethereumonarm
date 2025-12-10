# Configuration file for the Sphinx documentation builder.
#
# This file only contains a selection of the most common options. For a full
# list see the documentation:
# https://www.sphinx-doc.org/en/master/usage/configuration.html

# -- Path setup --------------------------------------------------------------

# If extensions (or modules to document with autodoc) are in another directory,
# add these directories to sys.path here. If the directory is relative to the
# documentation root, use os.path.abspath to make it absolute, like shown here.
#
# import os
# import sys
# sys.path.insert(0, os.path.abspath('.'))

import sphinx_rtd_theme

# -- Project information -----------------------------------------------------

project = 'Ethereum on ARM documentation'
copyright = '2025, Diego Losada <dlosada@ethereumonarm.com>, Fernando Collado <fernando@ethereumonarm.com>'
author = 'Diego Losada <dlosada@ethereumonarm.com>, Fernando Collado <fernando@ethereumonarm.com>'

release = '25.11.00'

rst_epilog = """
.. |release| replace:: {release}
""".format(release=release)

# Generate dynamic download links for each board
# We define both a substitution (|board_file|) and a target (_board_file)
# This allows using |board_file|_ in RST to get a link with the filename as text.
boards = [
    # (board_id, file_prefix, sha256_checksum)
    ('nanopct6', 'ethonarm_nanopct6', 'f60ca9cdef2bd0815761f61b497f655dd5486c53da67e6e2487d33264a173664'),
    ('rock5b', 'ethonarm_rock5b', 'a61a0cd5bd41bfcb1528e527878c15c158aedad6f745eeeb02975d300b3d2b42'),
    ('orangepi5-plus', 'ethonarm_orangepi5-plus', '1c28775acbe529e7cc31d1a819e76477820fea04c7e30a53a95488bf195ff8e0'),
    ('rpi5', 'ethonarm_rpi5', '4cc62f68376bec1dca1cee6ec5b1cb284202de084f046559ac5cb32eb2c647c8')
]

for board_id, file_prefix, sha256 in boards:
    filename = f"{file_prefix}_{release}.img.zip"
    url = f"https://github.com/EOA-Blockchain-Labs/ethereumonarm/releases/download/v{release}/{filename}"
    token = f"{board_id}_file" # e.g., nanopct6_file
    checksum_token = f"{board_id}_sha256" # e.g., nanopct6_sha256
    
    # Define substitution for the text (filename)
    rst_epilog += f".. |{token}| replace:: {filename}\n"
    # Define substitution for the checksum with inline code formatting
    rst_epilog += f".. |{checksum_token}| replace:: ``{sha256}``\n"
    # Define the link target
    rst_epilog += f".. _{token}: {url}\n"


# -- General configuration ---------------------------------------------------

# Add any Sphinx extension module names here, as strings. They can be
# extensions coming with Sphinx (named 'sphinx.ext.*') or your custom
# ones.
extensions = [
    "sphinx_rtd_theme",
    "sphinx_tabs.tabs",
    "sphinx-prompt"
]

# Add any paths that contain templates here, relative to this directory.
templates_path = ['_templates']

# List of patterns, relative to source directory, that match files and
# directories to ignore when looking for source files.
# This pattern also affects html_static_path and html_extra_path.
exclude_patterns = ['_build', 'Thumbs.db', '.DS_Store']


# -- Options for HTML output -------------------------------------------------

# The theme to use for HTML and HTML Help pages.  See the documentation for
# a list of builtin themes.
#
html_theme = 'sphinx_rtd_theme'
html_logo = '_static/images/eoa_logo.png'
html_css_files = [
    'css/custom.css',
]

# Add any paths that contain custom static files (such as style sheets) here,
# relative to this directory. They are copied after the builtin static files,
# so a file named "default.css" will overwrite the builtin "default.css".
html_static_path = ['_static']
