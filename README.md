# BigInsights-Isilon-OneFS8-Scripts
Admin Scripts for IBM Biginsights 4.1 &amp; EMC Isilon OneFS v 8

BigInsights (BI) is IBM's Hadoop Distribution, you can deploy BI in a typical direct attached storage (DAS) fashion or better yet deploy BI in a robust scale out network attached storage (NAS) architecture. Using EMC's Isilon NAS solution allows you to run the name nodes and data nodes right on the scale out NAS itself. This provides name node redundancy, data deduplication (non existant with DAS), better access and security controls, multiprotocol support (run HDFS, NFS, SMB, SWIFT, HTTP, SSH, and FTP simultaneously), provide better snapshots, etc.

The scripts posted here provide the same functions as the scripts provided in the BigInsights repository, however thay have been adapted to support the recently released EMC Isilon OneFS v 8 software.

These scripts also support new user/group requirements in IBM BigInsights v 4.1.

Regards,

Boni Bruno | Principal Solutions Architect | EMC
