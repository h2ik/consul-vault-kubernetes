FROM vault:0.7.0
LABEL maintainer "Jon Whitcraft <jwhitcraft@sugarcrm.com>"

# Provide for envsubst from gettext
RUN apk add --no-cache gettext curl

# These additional packages won't be necessary after dev stage
RUN apk add --no-cache bash

# Replace docker-entrypoint with one that doesn't rewrite args for dev version!
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["docker-entrypoint.sh"]

EXPOSE 8201

CMD ["vault", "server", "-config", "/vault/config"]
