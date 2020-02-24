# [symbol-openapi-generator](https://github.com/nemtech/symbol-openapi-generator)

[![Build Status](https://travis-ci.org/nemtech/symbol-openapi-generator.svg?branch=master)](https://travis-ci.org/nemtech/symbol-openapi-generator)

Project in charge of generating the API client libraries used by the Symbol SDKs.

The ``generate`` script creates different flavours of clients according to the [current OpenAPI specification](https://github.com/nemtech/symbol-openapi).

## Supported languages
| Language   | Template          | 
|------------|------------------|
| Typescript | typescript-node  |
| Java       | vertx            |
|            | jersey2          |
|            | okhttp-gson      |

See possible options for languages and flavours [here](https://openapi-generator.tech/docs/generators/).

## Requirements

* NPM 8
* Java 8

## Usage

Once you have installed the dependencies, run:
~~~~
npm install @openapitools/openapi-generator-cli@cli-4.1.0 -g
./generate.sh all build
~~~~

The script will:

1. Generate one library per language / template / framework.
2. Build each library.
3. Build and install libraries using NPM and Gradle.

## Notes for SDKs developers

* Running the generator is not required to build the SDKs. The generated libs are published into a central repository (e.g. maven, npm).  The SDKs depend on those libraries like any other third party dependency.
* The generated lib version (artifact version) should be consistent with the OpenAPI spec. For instance, if the current version is 0.7.19,  the generated libraries should have version 0.7.19. If the descriptor changes and the version is updated, the libraries should be upgraded, regenerated, and deployed.
* The generator uses a patched version of the descriptor due to the AnyOf  [bug](https://github.com/OpenAPITools/openapi-generator/issues/634).
* There is a small tune in the java generation that uses BigInteger attributes instead of String when a field is a String number. The tune is by using ``typeMappings =  ["x-number-string": "java.math.BigInteger"]`` and by replacing the string type to ``x-number-string`` in the ``openapi3-any-of-patch.yaml``.
* ⚠️Generated code must not be changed not committed!!! Note that the ``build`` folder is gitignored. If there is something wrong with the generated code, you need to [customize the generator](https://openapi-generator.tech/docs/customization.html).

## License

Copyright (c) 2020-present NEM
Licensed under the [Apache License 2.0](LICENSE)
