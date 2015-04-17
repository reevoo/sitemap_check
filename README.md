# Sitemap Check

## Install

`gem install sitemap_check`

## Usage

```bash
$ CHECK_URL=http://reevoo.com/sitemap_index.xml sitemap_check
```

## Config

Config can be set with enviroment variables

variable     | default | description
-------------|---------|-------------
`CHECK_URL`  | `nil`   | The url of the sitemap or sitemap index to check
`CONCURRENCY`| `10`    | The number of concurent threads to use when checking the sitemap
