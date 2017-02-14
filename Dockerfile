FROM quay.io/assemblyline/alpine:3.5

RUN apk add --no-cache --virtual .builddeps \
      build-base \
      ruby-dev=2.3.3-r100 \
      ruby=2.3.3-r100 \
      zlib-dev \
    && gem install sitemap_check --no-document \
    && runDeps="$( \
      scanelf --needed --nobanner --recursive /usr/lib/ruby/gems \
        | awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
        | sort -u \
        | xargs -r apk info --installed \
        | sort -u \
      )" \
    && apk add --no-cache --virtual .rundeps $runDeps ruby=2.3.3-r100 ca-certificates \
    && apk del --no-cache .builddeps
ENTRYPOINT ["sitemap_check"]
