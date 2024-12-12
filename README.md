# Building Scalable Multi-Tenancy Authentication and Authorization using Open Standards and Open-Source Software: Keycloak, OpenFGA and Apache APISIX

This repository contains a PoC implemented with [Keycloak](https://www.keycloak.org/) integrated with [OpenFGA](https://openfga.dev/) and Apache APISIX on how build a scalable multi-tenancy architecture based Open Standards and Open-Source Software (OSS).


This workshop is based the following article [Building Scalable Multi-Tenancy Authentication and Authorization using Open Standards and Open-Source Software](https://embesozzi.medium.com/building-scalable-multi-tenancy-authentication-and-authorization-using-open-standards-and-7341fcd87b64). You will find there full details about the authorization architecture guidelines and involved components.

# How to install?
## Prerequisites

 * Install Git, [Docker](https://www.docker.com/get-docker) and [Docker Compose](https://docs.docker.com/compose/install/#install-compose) in order to run the steps provided in the next section<br>

## Deploy the on-click deployment PoC

1. Clone this repository
    ````bash
    git clone https://github.com/embesozzi/keycloak-openfga-multitenancy-workshop
    cd keycloak-openfga-multitenancy-workshop
    ````

2. Execute following Docker Compose command to start the deployment

   ```sh
   ./mutitenancy-workshop.sh
   ```

3. To be able to use this environment, you need to add this line to your local HOSTS file:

   ```sh
   127.0.0.1 payplus.lab keycloak openfga
   ```

4. Access the following web UIs using URLs bellow via a web browser.

    | Component                 |  URI                          |  Credential               | Image                                    |
    | ------------------------- |:-----------------------------:|:-------------------------:|:-----------------------------------------:
    | Keycloak Console          |   http://keycloak:8081        |  admin / password         | quay.io/keycloak/keycloak:26.0.6         |
    | OpenFGA Playground        |   http://localhost:3000/playground  |                     | openfga/openfga:v1.8.0                   | 
    | Store Portal              |   http://payplus.lab:4000           |                           | Custom image                             |


## Test cases

The test cases are described in the article [Building Scalable Multi-Tenancy Authentication and Authorization using Open Standards and Open-Source Software](https://embesozzi.medium.com/building-scalable-multi-tenancy-authentication-and-authorization-using-open-standards-and-7341fcd87b64).

