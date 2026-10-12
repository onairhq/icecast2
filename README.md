# Icecast2 Docker Image

A multi-platform Docker image for [Icecast](https://icecast.org/), built directly from the upstream source code.

## Documentations

[onairhq/liquidsoap](https://github.com/onairhq/liquidsoap)
[onairhq/web](https://github.com/onairhq/web)

## Supported Platforms

| OS    | Architecture |
| ----- | ------------ |
| Linux | `amd64`      |
| Linux | `arm64`      |

## Environment Variables

Configure the Icecast server using the following environment variables.

| Variable                  | Default                   | Description                                     |
| ------------------------- | ------------------------- | ----------------------------------------------- |
| `ICECAST_HOSTNAME`        | `localhost`               | Icecast server hostname                         |
| `ICECAST_LOCATION`        | `Earth`                   | Physical location of the server                 |
| `ICECAST_ADMIN_EMAIL`     | `icecastmaster@localhost` | Administrator contact email                     |
| `ICECAST_PORT`            | `8000`                    | Icecast listening port                          |
| `ICECAST_SOURCE_PASSWORD` | `change-me`               | Password for source connections                 |
| `ICECAST_RELAY_PASSWORD`  | `change-me`               | Password for relay connections                  |
| `ICECAST_ADMIN_USER`      | `admin`                   | Administrator username                          |
| `ICECAST_ADMIN_PASSWORD`  | `change-me`               | Administrator password                          |
| `ICECAST_MAX_CLIENTS`     | `100`                     | Maximum number of concurrent client connections |
| `ICECAST_MAX_SOURCES`     | `2`                       | Maximum number of source connections            |

**Security:** Change all default passwords before exposing the server to a public network.

## Getting Started

### Pull the Image

Pull the latest image:

```bash
docker pull ghcr.io/onairhq/icecast2:latest
```

Or pull a specific Icecast version:

```bash
docker pull ghcr.io/onairhq/icecast2:2.5.0
```

### Run the Container

Start Icecast with the default configuration:

```bash
docker run -d \
  --name icecast \
  --restart unless-stopped \
  -p 8000:8000 \
  ghcr.io/onairhq/icecast2:latest
```

The web interface will be available at:

http://localhost:8000/

### Configure the Server

Customize the server using environment variables:

```bash
docker run -d \
  --name icecast \
  --restart unless-stopped \
  -p 8000:8000 \
  -e ICECAST_HOSTNAME=stream.example.com \
  -e ICECAST_LOCATION=Earth \
  -e ICECAST_ADMIN_EMAIL=admin@example.com \
  -e ICECAST_SOURCE_PASSWORD='replace-with-a-strong-password' \
  -e ICECAST_RELAY_PASSWORD='replace-with-a-strong-relay-password' \
  -e ICECAST_ADMIN_USER=admin \
  -e ICECAST_ADMIN_PASSWORD='replace-with-a-strong-admin-password' \
  ghcr.io/onairhq/icecast2:latest
```

## Image Tags

| Tag      | Description                                      |
| -------- | ------------------------------------------------ |
| `latest` | Latest published image                           |
| `2.5.0`  | Image built for Icecast upstream version `2.5.0` |

The version tag identifies the upstream Icecast version, not an immutable Docker image revision. The image may be rebuilt or updated with changes to the Docker packaging, configuration, dependencies, or entrypoint without changing the upstream Icecast version.

For reproducible deployments, pin the image by digest when an immutable image reference is required.

## Acknowledgements

This project was inspired by [libretime/icecast-docker](https://github.com/libretime/icecast-docker)

<div align=center>
    <p>Built with passion for open-source streaming</p>
</div>
