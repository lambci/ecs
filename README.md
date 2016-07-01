Building
--------

    docker build --pull -t lambci/ecs .

Testing
-------

    docker run -v /var/run/docker.sock:/var/run/docker.sock \
      -e GITHUB_TOKEN=$LAMBCI_GITHUB_TOKEN -e SLACK_TOKEN=$LAMBCI_SLACK_TOKEN -e SLACK_CHANNEL="#test" \
      -e LAMBCI_COMMIT=f7fa87465ddf38bb557ff7ebdd1b46564296cf12 -e LAMBCI_REPO=mhart/test-ci-project \
      lambci/ecs

