FROM quay.io/assemblyline/alpine:3.5

MAINTAINER ed@reevoo.com
ARG VERSION
RUN apk add --no-cache --virtual .builddeps \
      build-base \
      ruby-dev=2.3.3-r100 \
      ruby=2.3.3-r100 \
      zlib-dev \
      libffi-dev \
    && gem install sitemap_check --no-document -v $VERSION \
    && runDeps="$( \
      scanelf --needed --nobanner --recursive /usr/lib/ruby/gems \
        | awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
        | sort -u \
        | xargs -r apk info --installed \
        | sort -u \
      )" \
    && apk add --no-cache --virtual .rundeps \
         $runDeps \
         ca-certificates \
         libcurl \
         ruby=2.3.3-r100 \
    && apk del --no-cache .builddeps
ENTRYPOINT ["sitemap_check"]
