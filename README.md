# Sitemap Check

[![Build Status](https://travis-ci.org/reevoo/sitemap_check.svg?branch=master)](https://travis-ci.org/reevoo/sitemap_check)
[![Code Climate](https://codeclimate.com/github/reevoo/sitemap_check/badges/gpa.svg)](https://codeclimate.com/github/reevoo/sitemap_check)
[![Test Coverage](https://codeclimate.com/github/reevoo/sitemap_check/badges/coverage.svg)](https://codeclimate.com/github/reevoo/sitemap_check/coverage)
[![Gem Version](https://badge.fury.io/rb/sitemap_check.svg)](https://rubygems.org/gems/sitemap_check)

## Install

`gem install sitemap_check`

## Usage

```bash
$ CHECK_URL=http://reevoo.com/sitemap_index.xml sitemap_check
```

`CHECK_URL` can also be passed as an argument to sitemap_check

```bash
$ sitemap_check http://reevoo.com/sitemap_index.xml
```

# Docker

```bash
$ docker run --rm quay.io/reevoo/sitemap_check https://reevoo.com/sitemap_index.xml
```

## Config

Config can be set with enviroment variables

variable     | default | description
-------------|---------|-------------
`CHECK_URL`  | `nil`   | The url of the sitemap or sitemap index to check
`CONCURRENCY`| `10`    | The number of concurent threads to use when checking the sitemap

