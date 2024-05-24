FROM alpine/git AS base

ARG TAG=latest
RUN git clone https://github.com/pagefaultgames/pokerogue.git && \
    cd pokerogue && \
    ([[ "$TAG" = "latest" ]] || git checkout ${TAG}) && \
    rm -rf .git && \
    sed -i 's/export const apiUrl/export let apiUrl/' src/utils.ts && \
    PATCH="\
        try {\n\
            const request = new XMLHttpRequest();\n\
            request.open('GET', '/api-url.txt', false);\n\
            request.send();\n\
            if (request.status === 200) { apiUrl = request.responseText; }\n\
        } catch (e) { console.error(e); }\n\
        " && \
    sed -i "/export let apiUrl/a$PATCH" src/utils.ts

FROM node:alpine AS build

WORKDIR /pokerogue
COPY --from=base /git/pokerogue .
RUN npm install && \
    npm run build

FROM lipanski/docker-static-website

COPY --from=build /pokerogue/dist .
