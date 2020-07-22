# symbol-openapi-generator

[![Build Status](https://travis-ci.com/nemtech/symbol-openapi-generator.svg?branch=main)](https://travis-ci.com/nemtech/symbol-openapi-generator)

Project in charge of generating the API client libraries used by the Symbol SDKs.

The ``generate`` script creates different flavours of clients according to the [current OpenAPI specification](https://github.com/nemtech/symbol-openapi).

## Supported languages
| Language   | Template         | 
|------------|------------------|
| Typescript | typescript-node  |
|            | typescript-fetch |
| Java       | vertx            |
|            | jersey2          |
|            | okhttp-gson      |
| Python     | python           |

See possible options for languages and flavours [here](https://openapi-generator.tech/docs/generators/).

## Requirements

* NPM 8
* Java 8

## Usage

Once you have installed the dependencies, run:
~~~~
npm install @openapitools/openapi-generator-cli@cli-4.3.1 yaml-cli@1.1.8  -g
bash download-and-patch.sh
bash generate.sh [template]
~~~~

The script will:

1. Download the released openapi3.yml from [symbol-openapi](https://github.com/nemtech/symbol-openapi/releases) of the current version (version.txt).
2. Create a patched version of the open api specification (see notes below).
3. Generate one library per language / template / framework.
4. Build each library.
5. Build and install libraries using PyPI, NPM and Gradle.

## Notes for SDKs developers

* Running the generator is not required to build the SDKs. The generated libs are published into a central repository (e.g. maven, npm).  The SDKs depend on those libraries like any other third party dependency.
* The generated lib version (artifact version) should be consistent with the OpenAPI spec. For instance, if the current version is 0.7.19,  the generated libraries should have version 0.7.19. If the descriptor changes and the version is updated, the libraries should be upgraded, regenerated, and deployed.
* The generator uses a patched version of the descriptor due to the AnyOf  [bug](https://github.com/OpenAPITools/openapi-generator/issues/634).
* There is a small tune in the java generation that uses BigInteger attributes instead of String when a field is a String number. The tune is by using ``typeMappings =  ["x-number-string": "java.math.BigInteger"]`` and by replacing the string type to ``x-number-string`` in the ``openapi3-any-of-patch.yaml``.
* ⚠️Generated code must not be changed not committed!!! Note that the ``build`` folder is gitignored. If there is something wrong with the generated code, you need to [customize the generator](https://openapi-generator.tech/docs/customization.html).

## License

Copyright (c) 2020-present NEM
Licensed under the [Apache License 2.0](LICENSE)
