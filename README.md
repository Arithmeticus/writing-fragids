# Writing Fragment Identifiers

Resources for Writing Fragment Identifiers ("Writing Fragids," WFs), a fragid scheme for URIs that designate text-bearing objects or written works.

Writing Fragids are intended for allow someone to take a URI that refers to a book, an article, or some other writing that is citable, and add a fragment to it, to specify a specific part. Such URIs are meant to be meaningful independent of any particular digital resource or media type, if it even exists.

For example, to refer to Walter Burkert's *Lore and Science in Ancient Pythagoreanism*, page 14 line 2, one may write:
```
http://www.worldcat.org/oclc/860129739#$wf0:a=w;t=m;r=.;14.2$
```

This URI can then be used in a variety of RDF statements. See the resources below for more examples and possible uses.

## Key components

* **Draft specifications**: [Docbook (master)](writing%20fragids.xml), [PDF](writing%20fragids.pdf) - introduction to WF URIs, with theoretical underpinnings, syntax definitions, and conformance requirements for media types and processors.
* [WF functions](wf-functions.xsl) - a non-normative function library in XSLT; includes a WF URI parser
* [WF examples](wf-examples.xsl) - examples of WF URIs in a variety of works and scripta
* [Oxygen project](wf.xpr), for managing the project, handling common tasks via [Oxygen XML Editor](https://www.oxygenxml.com/).

The subdirectory [tests](tests) contains XSpec resources to test the conformance suite; [schemas](schemas) contains schemas for various resources.

Other subdirectories such as [TEI](TEI) and [TAN](TAN) are, or will be, populated with resources illustrating how a media type can develop its on WF conformance specifications.

## Status

Writing Fragids are an experimental technology. The specifications are currently being explored, developed, and tested. Discussions for WFs are being conducted by Joel Kalvesmaki as a part of W3C's [LD4LT community group](https://www.w3.org/community/ld4lt/) in a [subcommittee devoted to consolidating Linked Open Data vocabulary for linguistic annotations](https://github.com/ld4lt/linguistic-annotation).

## License

All software, code, and dependencies are released under a GNU General Public License.

All other materials (e.g., specifications), unless otherwise specified, are licensed under a Creative Commons Attribution 4.0 International License