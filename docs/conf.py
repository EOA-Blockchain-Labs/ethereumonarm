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



# -- Project information -----------------------------------------------------

project = 'Ethereum on ARM documentation'
copyright = '2025, Ethereum on ARM, Ethereum on ARM'
author = 'Ethereum on ARM, Ethereum on ARM'

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

    "sphinx_tabs.tabs",
    "sphinx-prompt",
    "sphinx_sitemap",
    "sphinx_copybutton",
    "sphinx_design",
]

# Sitemap configuration
html_baseurl = 'https://ethereum-on-arm-documentation.readthedocs.io/en/latest/'
sitemap_url_scheme = "{lang}{version}{link}"

# Add any paths that contain templates here, relative to this directory.
templates_path = ['_templates']

# List of patterns, relative to source directory, that match files and
# directories to ignore when looking for source files.
# This pattern also affects html_static_path and html_extra_path.
exclude_patterns = ['_build', 'Thumbs.db', '.DS_Store']


# -- Options for HTML output -------------------------------------------------

# Add any paths that contain custom static files (such as style sheets) here,
# relative to this directory. They are copied after the builtin static files,
# so a file named "default.css" will overwrite the builtin "default.css".
html_static_path = ['_static']

html_css_files = [
    'css/custom.css',
]

# The theme to use for HTML and HTML Help pages.  See the documentation for
# a list of builtin themes.
#
html_theme = 'furo'
html_logo = '_static/images/eoa_logo.png'

html_theme_options = {
    "sidebar_hide_name": True,
    "announcement": "Welcome to the new Ethereum on ARM documentation!",
    "footer_icons": [
        {
            "name": "GitHub",
            "url": "https://github.com/EOA-Blockchain-Labs/ethereumonarm",
            "html": """
                <svg stroke="currentColor" fill="currentColor" stroke-width="0" viewBox="0 0 16 16">
                    <path fill-rule="evenodd" d="M8 0C3.58 0 0 3.58 0 8c0 3.54 2.29 6.53 5.47 7.59.4.07.55-.17.55-.38 0-.19-.01-.82-.01-1.49-2.01.37-2.53-.49-2.69-.94-.09-.23-.48-.94-.82-1.13-.28-.15-.68-.52-.01-.53.63-.01 1.08.58 1.23.82.72 1.21 1.87.87 2.33.66.07-.52.28-.87.51-1.07-1.78-.2-3.64-.89-3.64-3.95 0-.87.31-1.59.82-2.15-.08-.2-.36-1.02.08-2.12 0 0 .67-.21 2.2.82.64-.18 1.32-.27 2-.27.68 0 1.36.09 2 .27 1.53-1.04 2.2-.82 2.2-.82.44 1.1.16 1.92.08 2.12.51.56.82 1.27.82 2.15 0 3.07-1.87 3.75-3.65 3.95.29.25.54.73.54 1.48 0 1.07-.01 1.93-.01 2.2 0 .21.15.46.55.38A8.013 8.013 0 0 0 16 8c0-4.42-3.58-8-8-8z"></path>
                </svg>
            """,
            "class": "",
        },
        {
            "name": "Twitter",
            "url": "https://twitter.com/EthereumOnARM",
            "html": """
                <svg stroke="currentColor" fill="currentColor" stroke-width="0" viewBox="0 0 16 16">
                    <path d="M5.026 15c6.038 0 9.341-5.003 9.341-9.334 0-.14 0-.282-.006-.422A6.685 6.685 0 0 0 16 3.542a6.658 6.658 0 0 1-1.889.518 3.301 3.301 0 0 0 1.447-1.817 6.533 6.533 0 0 1-2.087.793A3.286 3.286 0 0 0 7.875 6.03a9.325 9.325 0 0 1-6.767-3.429 3.289 3.289 0 0 0 1.018 4.382A3.323 3.323 0 0 1 .64 6.575v.045a3.288 3.288 0 0 0 2.632 3.218 3.203 3.203 0 0 1-.865.115 3.23 3.23 0 0 1-.614-.057 3.283 3.283 0 0 0 3.067 2.277A6.588 6.588 0 0 1 .78 13.58a6.32 6.32 0 0 1-.78-.045A9.344 9.344 0 0 0 5.026 15z"></path>
                </svg>
            """,
            "class": "",
        },
    ],
}
