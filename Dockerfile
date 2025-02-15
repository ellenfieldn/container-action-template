# Set the base image to use for subsequent instructions
FROM node:slim AS base_image


LABEL com.github.actions.name="Container Toolkit Action -- Nodist" \
  com.github.actions.description="Sample Typescript container action without dist folder" \
  com.github.actions.icon="code" \
  com.github.actions.color="red" \
  maintainer="@ellenfieldn" \
  org.opencontainers.image.authors="Container Toolkit Action Nodist Contributors: https://github.com/ellenfieldn/container-action-template/graphs/contributors" \
  org.opencontainers.image.url="https://github.com/ellenfieldn/container-action-template" \
  org.opencontainers.image.source="https://github.com/ellenfieldn/container-action-template" \
  org.opencontainers.image.documentation="https://github.com/ellenfieldn/container-action-template" \
  org.opencontainers.image.description="Sample Typescript container action without dist folder"

# Create a directory for the action code
RUN mkdir -p /usr/src/app

# Set the working directory inside the container.
WORKDIR /usr/src/app

# Copy the repository contents to the container
COPY . .

RUN npm install

RUN npm run all

# Run the specified command within the container
ENTRYPOINT ["node", "/usr/src/app/dist/index.js"]

#######################################################
# Slim Image
#######################################################
# Define the different versions of the image
FROM base_image AS slim
RUN echo "this is the slim version"

# Set build metadata here so we don't invalidate the container image cache if we
# change the values of these arguments
ARG BUILD_DATE
ARG BUILD_REVISION
ARG BUILD_VERSION

LABEL org.opencontainers.image.created=$BUILD_DATE \
  org.opencontainers.image.revision=$BUILD_REVISION \
  org.opencontainers.image.version=$BUILD_VERSION

ENV BUILD_DATE=$BUILD_DATE
ENV BUILD_REVISION=$BUILD_REVISION
ENV BUILD_VERSION=$BUILD_VERSION


#######################################################
# Standard Image
#######################################################
FROM base_image AS standard
RUN echo "this is the standard version"

# Set build metadata here so we don't invalidate the container image cache if we
# change the values of these arguments
ARG BUILD_DATE
ARG BUILD_REVISION
ARG BUILD_VERSION

LABEL org.opencontainers.image.created=$BUILD_DATE \
  org.opencontainers.image.revision=$BUILD_REVISION \
  org.opencontainers.image.version=$BUILD_VERSION

ENV BUILD_DATE=$BUILD_DATE
ENV BUILD_REVISION=$BUILD_REVISION
ENV BUILD_VERSION=$BUILD_VERSION

#######################################################
# Extra Image
#######################################################
FROM base_image AS extra
RUN echo "this is the extra version"

# Set build metadata here so we don't invalidate the container image cache if we
# change the values of these arguments
ARG BUILD_DATE
ARG BUILD_REVISION
ARG BUILD_VERSION

LABEL org.opencontainers.image.created=$BUILD_DATE \
  org.opencontainers.image.revision=$BUILD_REVISION \
  org.opencontainers.image.version=$BUILD_VERSION

ENV BUILD_DATE=$BUILD_DATE
ENV BUILD_REVISION=$BUILD_REVISION
ENV BUILD_VERSION=$BUILD_VERSION
