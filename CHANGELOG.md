# CHANGELOG.md

## 1.0.0 (2024-12-28)

Features:

- Drop ruby 2.5/2.6 support
- Add appraisals

Fix:

- Fix ruby-kafka health-check bug for some ActiveSupport versions

## 0.5.0 (2023-08-16)

Features:

- Add Sidekiq 6+ support [PR#4](https://github.com/SberMarket-Tech/http_health_check/pull/4)

## 0.4.1 (2022-08-05)

Fix:

- Fix DelayedJob probe [PR#2](https://github.com/SberMarket-Tech/http_health_check/pull/2)

## 0.4.0 (2022-07-20)

Features:

- add karafka consumer groups utility function

## 0.3.0 (2022-07-19)

Features:

- add ruby-kafka probe

## 0.2.1 (2022-07-18)

Fix:

- fix gemspec

## 0.2.0 (2022-07-18)

Features:

- add an ability to configure logger

Fix:

- fix builtin probes requirement

## 0.1.1 (2022-07-17)

Features:

- implement basic functionality
- add builtin sidekiq probe
- add builtin delayed job probe
