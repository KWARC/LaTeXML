# LaTeXML KWARC Fork Changes

This document contains a list of changes compared to the upstream LaTeXML repository. 
It lists important commits, to give a rough overview of what has happened since divergence. 

## Locators

Introduces XPointer Syntax for Locators, and also ranges instead of points. 

* [b0a459cd](https://github.com/KWARC/LaTeXML/commit/b0a459cd)  improve generic source names and improve ranges
* [9218b7ea](https://github.com/KWARC/LaTeXML/commit/9218b7ea)	keep track of SOURCEBASE global variable (TODO: not sure if this is related to Locators and how this is used)
* [d801ffdd](https://github.com/KWARC/LaTeXML/commit/d801ffdd)	first version of textrange locators
* [862e77c3](https://github.com/KWARC/LaTeXML/commit/862e77c3)	add XPointer Notation for locators

## Support for URI & empty input

Implemented support for using content at a given URL as input to LaTeXML. 


* [693ba4c3](https://github.com/KWARC/LaTeXML/commit/693ba4c3)	https support
* [1598760c](https://github.com/KWARC/LaTeXML/commit/1598760c)	[44353f42](https://github.com/KWARC/LaTeXML/commit/44353f42)    URL support for \input
* [defbdb36](https://github.com/KWARC/LaTeXML/commit/defbdb36)	allow empty input files

## Support for multiple input files

Initial implementation of multiple files (preamble, postamble) as input for LaTeXML. 

* [6c2b795b](https://github.com/KWARC/LaTeXML/commit/6c2b795b)	allow preambles to be strings
* [ab54ab15](https://github.com/KWARC/LaTeXML/commit/ab54ab15)  add embeddable XHTML snippets
* [0dee59d7](https://github.com/KWARC/LaTeXML/commit/0dee59d7)	[6af98fae](https://github.com/KWARC/LaTeXML/commit/6af98fae)  [a0f85d58](https://github.com/KWARC/LaTeXML/commit/a0f85d58)	properly wrap fragments with \begin \end document when needed
* [bee6ded6](https://github.com/KWARC/LaTeXML/commit/bee6ded6)  do not write joined fragments to disk, instead keep it virtual (in-memory)
* [399a6a7f](https://github.com/KWARC/LaTeXML/commit/399a6a7f)  support for fragments by creating a file of joined \input s

## EPUB(3) Support

Added initial support for EPub Output. 

* Improve EPUB(3) Compliance
    * [9db98de5](https://github.com/KWARC/LaTeXML/commit/9db98de5)	use user-specified dc:identifier; ignore RDFa
    * [eca0c63f](https://github.com/KWARC/LaTeXML/commit/eca0c63f)	using proper time zone
    * [e4700255](https://github.com/KWARC/LaTeXML/commit/e4700255)	add meta element
    * [0436d951](https://github.com/KWARC/LaTeXML/commit/0436d951)	create seperate XSLT stylesheet
    * [886abe78](https://github.com/KWARC/LaTeXML/commit/886abe78)	[4f4004b0](https://github.com/KWARC/LaTeXML/commit/4f4004b0) manifest improvements
    * [e45b95e5](https://github.com/KWARC/LaTeXML/commit/e45b95e5)	adding toc.ncx file
    * [5b101113](https://github.com/KWARC/LaTeXML/commit/5b101113)	EPUB's content.opf improvement
    * [4bd79d58](https://github.com/KWARC/LaTeXML/commit/4bd79d58)	improve Text and Styles directories
    * [ada08bbd](https://github.com/KWARC/LaTeXML/commit/ada08bbd)	better handling of files for archive creation
* [3070caa3](https://github.com/KWARC/LaTeXML/commit/3070caa3)	initial configuration support for eBook formats

## ODT / DOCX Output

Adding support for ODT documents. 

Has since been split into a seperate plugin at [KWARC/LaTeXML-Plugin-Doc](https://github.com/KWARC/LaTeXML-Plugin-Doc). 

* [adf79643](https://github.com/KWARC/LaTeXML/commit/adf79643)  [e77cc39d](https://github.com/KWARC/LaTeXML/commit/e77cc39d)	Math Support
* [c1b21b21](https://github.com/KWARC/LaTeXML/commit/c1b21b21)	[22f30e71](https://github.com/KWARC/LaTeXML/commit/22f30e71)	Bugfixes
* [45216c83](https://github.com/KWARC/LaTeXML/commit/45216c83)	[1544c300](https://github.com/KWARC/LaTeXML/commit/1544c300)    Improved styling
* [5911f400](https://github.com/KWARC/LaTeXML/commit/5911f400)  [608194b3](https://github.com/KWARC/LaTeXML/commit/608194b3)  [e95e77c4](https://github.com/KWARC/LaTeXML/commit/e95e77c4)  bibliography
* [a96f4eb3](https://github.com/KWARC/LaTeXML/commit/a96f4eb3)  [fd509676](https://github.com/KWARC/LaTeXML/commit/fd509676)  [35146195](https://github.com/KWARC/LaTeXML/commit/35146195)  [a52e151e](https://github.com/KWARC/LaTeXML/commit/a52e151e)	[da920396](https://github.com/KWARC/LaTeXML/commit/da920396) Modularization and stylsheet updates
* [699c2fa1](https://github.com/KWARC/LaTeXML/commit/699c2fa1)	updating zip file structure
* [e258af2b](https://github.com/KWARC/LaTeXML/commit/e258af2b)  [5e1da535](https://github.com/KWARC/LaTeXML/commit/5e1da535)  [620810c0](https://github.com/KWARC/LaTeXML/commit/620810c0)  [d25037d8](https://github.com/KWARC/LaTeXML/commit/d25037d8)  [7f82ded2](https://github.com/KWARC/LaTeXML/commit/7f82ded2)    [2ed8697a](https://github.com/KWARC/LaTeXML/commit/2ed8697a)    [67489ed3](https://github.com/KWARC/LaTeXML/commit/67489ed3)    [894bc5c0](https://github.com/KWARC/LaTeXML/commit/894bc5c0)     [b2fbd49a](https://github.com/KWARC/LaTeXML/commit/b2fbd49a) misc improvements
* [d2684b60](https://github.com/KWARC/LaTeXML/commit/d2684b60)	initial LaTeXODT support


## Mathematics Improvements

Added several improvements to the math processing of LaTeXML. 

* [898d9483](https://github.com/KWARC/LaTeXML/commit/898d9483)	bindings for automath macros \ensuremathfollows and \ensuremathpreceeds
* [58b2aa13](https://github.com/KWARC/LaTeXML/commit/58b2aa13)	left-right nary joins
* [c20e34ca](https://github.com/KWARC/LaTeXML/commit/c20e34ca)	Support for arbitrary LaTeXML::grammars for math parsing
* [cd97da1c](https://github.com/KWARC/LaTeXML/commit/cd97da1c)	support for html with math images
* [d426e42d](https://github.com/KWARC/LaTeXML/commit/d426e42d)	fix for parallel xmath
* [be626bbd](https://github.com/KWARC/LaTeXML/commit/be626bbd)	fix to support proper selection of parent math node
* [95d4e415](https://github.com/KWARC/LaTeXML/commit/95d4e415)	preserving the Math element IDs in output
* [187a817c](https://github.com/KWARC/LaTeXML/commit/187a817c)	adding parallel parallel (sic) math modes
* [b55d125f](https://github.com/KWARC/LaTeXML/commit/b55d125f)	adding stack trace of notes during processing

### MathML

* [3aaab753](https://github.com/KWARC/LaTeXML/commit/3aaab753)	csymbol improvements
* [d0b1af65](https://github.com/KWARC/LaTeXML/commit/d0b1af65) [6272e694](https://github.com/KWARC/LaTeXML/commit/6272e694) [f9d5077d](https://github.com/KWARC/LaTeXML/commit/f9d5077d) [8416ebba](https://github.com/KWARC/LaTeXML/commit/8416ebba) [31b2f0f0](https://github.com/KWARC/LaTeXML/commit/31b2f0f0) [feb5fc68](https://github.com/KWARC/LaTeXML/commit/feb5fc68) implementation of set relations
* [0632f729](https://github.com/KWARC/LaTeXML/commit/0632f729)  add cmml support for sqrt and root
* [d365b4ad](https://github.com/KWARC/LaTeXML/commit/d365b4ad)  [bd2825f0](https://github.com/KWARC/LaTeXML/commit/bd2825f0)    [5072c7f4](https://github.com/KWARC/LaTeXML/commit/5072c7f4)    Improving Crossref operator
* [e1e442f4](https://github.com/KWARC/LaTeXML/commit/e1e442f4)  [799c8142](https://github.com/KWARC/LaTeXML/commit/799c8142)     [d44ac764](https://github.com/KWARC/LaTeXML/commit/d44ac764)   [fa816458](https://github.com/KWARC/LaTeXML/commit/fa816458)    Implementation of decorators

### OpenMath

* [75c3f1a9](https://github.com/KWARC/LaTeXML/commit/75c3f1a9)	use IC Variants in post-processing
* [239b3730](https://github.com/KWARC/LaTeXML/commit/239b3730)  [1a63f19f](https://github.com/KWARC/LaTeXML/commit/1a63f19f) convert math-nested ltx:XMText to OMSTRs
* [7b6209b5](https://github.com/KWARC/LaTeXML/commit/7b6209b5)  better names for OMV elements, in line with regex found in spec
* [8e8d622a](https://github.com/KWARC/LaTeXML/commit/8e8d622a)  support for OpenMath Plus Symbol
* [d53729a6](https://github.com/KWARC/LaTeXML/commit/d53729a6)	support for OMBIND

## Bindings

Added support for multiple new bindings and updated existing ones. 

* [f147a510](https://github.com/KWARC/LaTeXML/commit/f147a510)	DeclareOption* (new)
* [41771817](https://github.com/KWARC/LaTeXML/commit/41771817)	turing.sty (new binding)
* [c9ea44a4](https://github.com/KWARC/LaTeXML/commit/c9ea44a4)	webgraphic (Improvements to Semiverbatim)
* [26e8ffbe](https://github.com/KWARC/LaTeXML/commit/26e8ffbe)	pgf (experimental implementation)
* [86cf5136](https://github.com/KWARC/LaTeXML/commit/86cf5136)  wiki.sty (read .sty file)
* [b7d938f7](https://github.com/KWARC/LaTeXML/commit/b7d938f7)	[1e9813ab](https://github.com/KWARC/LaTeXML/commit/1e9813ab)    \meaning (Improvement)
* [80ca45a0](https://github.com/KWARC/LaTeXML/commit/80ca45a0)	InputFile (BugFix)
* [71dd4d01](https://github.com/KWARC/LaTeXML/commit/71dd4d01)	lstlisting (BugFix)

## RDFa improvements

Improved support for RDF(a) output. 

* [dd44f731](https://github.com/KWARC/LaTeXML/commit/dd44f731)	updates to RDFa
* [35320b5b](https://github.com/KWARC/LaTeXML/commit/35320b5b)	ensuring no XHTML-style empty divs are produced for RDFa
* [dc192879](https://github.com/KWARC/LaTeXML/commit/dc192879)  [19adf44f](https://github.com/KWARC/LaTeXML/commit/19adf44f)    metadata handling, for RDFa 1.1
* [bc814fb6](https://github.com/KWARC/LaTeXML/commit/bc814fb6)	updating to support RDFa and custom namespaces
* [4b28ccae](https://github.com/KWARC/LaTeXML/commit/4b28ccae)  [96ab04f3](https://github.com/KWARC/LaTeXML/commit/96ab04f3)    add RDFa attributes to note element

## KWARC-specific bindings

Implemented bindings for several kwarc-specific systems / packages. 

### STeX

Has since been refactored into [KWARC/latexml-plugin-stex](https://github.com/kwarc/latexml-plugin-stex). 

* [808fc64e](https://github.com/KWARC/LaTeXML/commit/808fc64e)  [800d33b0](https://github.com/KWARC/LaTeXML/commit/800d33b0)  stex profiles and preloading
* [af6097ec](https://github.com/KWARC/LaTeXML/commit/af6097ec) [9be1f136](https://github.com/KWARC/LaTeXML/commit/9be1f136) stex web service
* [850663c8](https://github.com/KWARC/LaTeXML/commit/850663c8)  [e6c84924](https://github.com/KWARC/LaTeXML/commit/e6c84924)    [766b5365](https://github.com/KWARC/LaTeXML/commit/766b5365)    [e8abe051](https://github.com/KWARC/LaTeXML/commit/e8abe051)    [289b4479](https://github.com/KWARC/LaTeXML/commit/289b4479)    bindings for slides


### MWS

Has since been moved into [KWARC/LaTeXML-Plugin-MathWebSearch](https://github.com/KWARC/LaTeXML-Plugin-MathWebSearch). 

* [31295dfe](https://github.com/KWARC/LaTeXML/commit/31295dfe)  [f20ee5b7](https://github.com/KWARC/LaTeXML/commit/f20ee5b7)    [b33742aa](https://github.com/KWARC/LaTeXML/commit/b33742aa)  [19be1f1c](https://github.com/KWARC/LaTeXML/commit/19be1f1c)  adding a ZBL class, schema & model
* [e9f8cfca](https://github.com/KWARC/LaTeXML/commit/e9f8cfca)  [b1c5559a](https://github.com/KWARC/LaTeXML/commit/b1c5559a)  adding mws qvar handling
* [680257cd](https://github.com/KWARC/LaTeXML/commit/680257cd)	mwsquery profile

### Marpa

Has since been refactored into [dginev/LaTeXML-Plugin-MathSyntax](https://github.com/dginev/LaTeXML-Plugin-MathSyntax). 

* [b263c9f8](https://github.com/KWARC/LaTeXML/commit/b263c9f8)  [a2ea56e5](https://github.com/KWARC/LaTeXML/commit/a2ea56e5)  [b59406ca](https://github.com/KWARC/LaTeXML/commit/b59406ca)  [bf53897e](https://github.com/KWARC/LaTeXML/commit/bf53897e)	extending and improving the Marpa grammar

### NNexus / PlanetMath

* [04168c33](https://github.com/KWARC/LaTeXML/commit/04168c33)	[750e88c1](https://github.com/KWARC/LaTeXML/commit/750e88c1)	NNexus bindings
* [3ca88c2a](https://github.com/KWARC/LaTeXML/commit/3ca88c2a)	[5f296ef7](https://github.com/KWARC/LaTeXML/commit/5f296ef7)    [0286cf6c](https://github.com/KWARC/LaTeXML/commit/0286cf6c)    webgraphics improvements
* [d7fdc338](https://github.com/KWARC/LaTeXML/commit/d7fdc338)	pmprivacy macro binding
* [2befd893](https://github.com/KWARC/LaTeXML/commit/2befd893)  [e4025d2d](https://github.com/KWARC/LaTeXML/commit/e4025d2d)	pmath.sty binding

## LateXML Dameon / Client Model

Introduced a daemon / client architecture for LaTeXML that has since been partially merged into upstream and refactored into [dginev/LaTeXML-Plugin-latexmls](https://github.com/dginev/LaTeXML-Plugin-latexmls). 

* [01d41e56](https://github.com/KWARC/LaTeXML/commit/01d41e56)  [7a43fcd2](https://github.com/KWARC/LaTeXML/commit/7a43fcd2)    [c3ec468a](https://github.com/KWARC/LaTeXML/commit/c3ec468a)	implementing server / client architecture
* [c43f1218](https://github.com/KWARC/LaTeXML/commit/c43f1218)  [6d999a63](https://github.com/KWARC/LaTeXML/commit/6d999a63)  [acd1b2f4](https://github.com/KWARC/LaTeXML/commit/acd1b2f4)  [076fb117](https://github.com/KWARC/LaTeXML/commit/076fb117) [46498db8](https://github.com/KWARC/LaTeXML/commit/46498db8)	adding multiple processing options
* [282ae4f8](https://github.com/KWARC/LaTeXML/commit/282ae4f8)	[a8b56867](https://github.com/KWARC/LaTeXML/commit/a8b56867)  [643310c9](https://github.com/KWARC/LaTeXML/commit/643310c9)	introduction of latexmldaemon


## ltxmojo: Web Editor / Web Service

Introduced a web demo for LaTeXML, that has since been moved into [dginev/LaTeXML-Plugin-ltxmojo](https://github.com/dginev/LaTeXML-Plugin-ltxmojo). 

* [f10352b1](https://github.com/KWARC/LaTeXML/commit/f10352b1)  [ff830c38](https://github.com/KWARC/LaTeXML/commit/ff830c38)	Zip Support
* [e2a56667](https://github.com/KWARC/LaTeXML/commit/e2a56667)  [03acf0b8](https://github.com/KWARC/LaTeXML/commit/03acf0b8)	JSONP support
* [4e07ba32](https://github.com/KWARC/LaTeXML/commit/4e07ba32)  [e5f7f8da](https://github.com/KWARC/LaTeXML/commit/e5f7f8da)	use Mojolicious
* [4a4fcff9](https://github.com/KWARC/LaTeXML/commit/4a4fcff9)  [e74ec6f0](https://github.com/KWARC/LaTeXML/commit/e74ec6f0)	adding web editor
* [f8f2e783](https://github.com/KWARC/LaTeXML/commit/f8f2e783)	adding a web framework

## Misc Other Changes
* [2ce40028](https://github.com/KWARC/LaTeXML/commit/2ce40028)  [6bca1964](https://github.com/KWARC/LaTeXML/commit/6bca1964)    modularizing the schema
* [b32df308](https://github.com/KWARC/LaTeXML/commit/b32df308)  accepting .bib bibliogrpahies with the --bibliography switch
* [1dddfc6c](https://github.com/KWARC/LaTeXML/commit/1dddfc6c)  bibliohraphy improvements: nocite{*} works like cite{*}
* [c4d9854f](https://github.com/KWARC/LaTeXML/commit/c4d9854f)  ltx:graphics improvements
* [39015d11](https://github.com/KWARC/LaTeXML/commit/39015d11)	adding @whilesw and friends

