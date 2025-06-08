# checkov:skip=CKV_DOCKER_7: Upstream image doesn't offer version tags

FROM infrastructureascode/hello-world
COPY ./hello_world .
EXPOSE 8080

# checkov:skip=CKV_DOCKER_2: Healthcheck not applicable.
# checkov:skip=CKV_DOCKER_3: No shell available; static binary runs safely as root in minimal container
ENTRYPOINT ["/hello_world"]
