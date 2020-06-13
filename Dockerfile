#####################################################
##       The Cardano Static Binaries Builder       ##
#####################################################

# LOAD ALPINE IMAGE
FROM alpine AS final

# ADDING BASH TO FULLY SUPPORT THE ENTRYPOINT
RUN apk add bash

# ADD BUILD SCRIPT
COPY builder /usr/local/bin

# FORCE BUILD COMMAND
ENTRYPOINT ["builder"]
CMD ["--help"]
