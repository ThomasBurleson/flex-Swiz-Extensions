This repository contains [customized extensions] for the [Swiz Framework](http://github.com/ThomasBurleson/swiz-framework).

Custom extension include the:

- LogProcessor:  versatile logging with optional output to FireBug
- GlobalExceptionLogger: Autoinstall global exception handler for FP10 or greater apps.
- DeepLinkProcessor: deeplinking using SWFAddress
- AsyncInterceptor:  dynamic async RPC response interception for data conversion

Also includes modified (slightly) ThunderBoltAS3 classes for logging to FireBug console.

### History:

- 9/30/2010: Moved custom extensions from [swiz-framework](http://github.com/ThomasBurleson/swiz-framework) repository


## Building

You can compile the library .swc file using:

	ant -f ./build/build.xml compile