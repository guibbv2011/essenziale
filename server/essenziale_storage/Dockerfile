# Stage 1: Build
FROM dart:stable AS build

# Install tools for dependency collection
RUN apt-get update -y && apt-get install -y --no-install-recommends \
    ca-certificates \
    libc6 \
    binutils \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy pubspec files and resolve dependencies
COPY pubspec.* ./
RUN dart pub get

# Copy source code and get dependencies offline
COPY . .
RUN dart pub get --offline

# Compile the server
RUN dart compile exe bin/essenziale_storage.dart -o bin/server

# Collect runtime dependencies into /deps
RUN mkdir -p /deps/lib /deps/etc/ssl/certs
# Copy ELF interpreter
RUN INTERPRETER=$(readelf -l bin/server | sed -n 's/.*\[Requesting program interpreter: \(.*\)\].*/\1/p') && \
    [ -n "$INTERPRETER" ] && cp -L "$INTERPRETER" /deps/lib/ || echo "No interpreter found"
# Copy shared libraries
RUN for lib in $(ldd bin/server | grep '=> /' | awk '{print $3}' | sort -u); do \
      [ -f "$lib" ] && cp -L "$lib" /deps/lib/ || echo "Skipping missing lib: $lib"; \
    done
# Copy DNS libraries and config
RUN cp -L /lib/x86_64-linux-gnu/libresolv.so.2 /deps/lib/libresolv.so.2 || echo "libresolv.so.2 not found"
RUN cp -L /lib/x86_64-linux-gnu/libnss_dns.so.2 /deps/lib/libnss_dns.so.2 || echo "libnss_dns.so.2 not found"
RUN echo "hosts: files dns" > /deps/etc/nsswitch.conf
# Copy CA certificates
RUN cp /etc/ssl/certs/ca-certificates.crt /deps/etc/ssl/certs/ || echo "CA certs not found"
# Debug: List contents of /deps
RUN find /deps -ls

# Stage 2: Runtime
FROM busybox:glibc
COPY --from=build /deps/lib/* /lib/
COPY --from=build /deps/etc/ /etc/
COPY --from=build /app/bin/server /app/bin/server
WORKDIR /app
EXPOSE 8080
CMD ["/app/bin/server"]
