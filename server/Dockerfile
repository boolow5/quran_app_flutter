FROM alpine:3.18

WORKDIR /app

# Copy the binary from the host's bin directory
COPY bin/quran_app /app/quran_app
COPY db/create_tables.sql /app/create_tables.sql

# Run the binary
CMD ["/app/quran_app"]
