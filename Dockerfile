# This Dockerfile creates a static build image for CI
# https://filebrowser.org/installation
# https://filebrowser.org/configuration/authentication-method
FROM dockerhub/filebrowser/filebrowser:latest
COPY ./app/build/outputs ./srv
COPY ./app/build/reports/lint-results.html ./srv/androidlint_report.html
Run cd /srv ls -l
