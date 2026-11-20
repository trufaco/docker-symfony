# docker-symfony
Docker base image for Symfony

## Images

`ghcr.io/trufaco/docker-symfony:{tag}` (AMD64 + ARM64), PHP-FPM + Caddy on Debian trixie:

| Tag   | PHP   | Notes |
|-------|-------|-------|
| `8.6` | 8.6.0 | No `grpc` and no `protobuf`: their releases and default branches do not compile on PHP 8.6 yet (open fixes: protocolbuffers/protobuf#31752, grpc/grpc#43991). `amqp`, `apcu`, `igbinary`, `imagick` and `redis` are built from pinned commits (see `8.6/Dockerfile`). Switch back to the PECL releases when they support 8.6. |
| `8.5` | 8.5.13 | |

`8.4` is not built in CI.
