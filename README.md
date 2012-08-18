ramona-ddi-instrument-creator
=============================

The Ramona DDI Instrument creator is a suite of XSL transformations designed to convert survey instruments documented in the [DDI-Lifecycle XML format](http://www.ddialliance.org). It is intended, at this stage, to act as a proof-of-concept for the ability to create static and dynamic survey instruments from well documentation metadata. As development continues it is anticipated that the Ramona transformations will serve as a major component for metadat-driven data collection.

At this stage, development is in the early stages, and as such the Ramona tool can (and probably will) fail to process valid DDI documents correctly.

The two main issues with the tool at this stage are around ID resolutions, specifically that :
 * all metadata exists within a single file
 * complex DDI ids within references are currently resolved only using the ID - the schema, agency and version are all ignored
The ability to correctly parse references to retrieve objects outside of the file is a major piece of work on the agenda.
