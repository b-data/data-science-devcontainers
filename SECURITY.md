## Supported Versions

Only Development Containers using the latest versions of Julia, Python or R are
supported with security updates.

## Reporting a Vulnerability

To report a vulnerability in Development Containers using a latest version,
email the maintainer <olivier.benz@b-data.ch>.

## Vulnerabilities in Prior Versions

Vulnerabilities in Development Containers using prior versions of Julia, Python
or R are not fixed.

Whenever a new version of Julia, Python or R is released, the previous version's
docker image[^1] is rebuilt once again and then frozen.

[^1]: Parent image of the Development Container

Frozen docker images *may* be rebuilt or extended if they fail to start or have
runtime issues.
