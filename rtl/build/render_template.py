#!/usr/bin/env python3

import os
import sys
from textwrap import dedent

from mako.template import Template

def render_template_file(template_fname, result_fname):
    template_basename = os.path.basename(template_fname)
    header_text = dedent("""\
        ////////////////////////////////////////////////////////////////////////////////
        // THIS FILE WAS AUTOMATICALLY GENERATED FROM ${filename}
        // DO NOT EDIT
        ////////////////////////////////////////////////////////////////////////////////

    """)
    header = Template(header_text).render(filename=template_basename)

    with open(template_fname, "r") as f:
        template = Template(f.read())
    rendered = template.render()
    output = header + rendered

    result_dirname = os.path.dirname(result_fname)
    os.makedirs(result_dirname, exist_ok=True)
    with open(result_fname, "w") as f:
        f.write(output)

def main():
    assert(len(sys.argv) == 3)
    render_template_file(*sys.argv[1:])

if __name__ == "__main__":
    main()

