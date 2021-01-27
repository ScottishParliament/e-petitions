# Scottish Petitions

This is the code base for the Scottish Parliament's petitions service (https://petitions.parliament.scot).

## Setup

We recommend using [Docker Desktop][1] to get setup quickly. If you'd prefer not to use Docker then you'll need Ruby (2.4+), Node (10+), PostgreSQL (9.6+) and Memcached (1.4+) installed.

### DNS

The application uses domains to differentiate between different aspects so you'll need to setup the following DNS records in your local `/etc/hosts` file:

```
127.0.0.1     scotspets.local albapets.local moderatepets.local
```

If you don't want to edit your `/etc/hosts` file or you're on Windows then you can use a public wildcard DNS like `scotspets.lvh.me` and override the default domains using a `.env.local` file:

```
EPETITIONS_HOST_EN=scotspets.lvh.me
EPETITIONS_HOST_GD=albapets.lvh.me
MODERATE_HOST=moderatepets.lvh.me
```

If you do this before running the app for the first time it will automatically pick these up, otherwise you'll need to use a PostgreSQL client to edit the `url_en`, `url_gd` and `moderate_url` columns on the record in the `sites` table.

### Create the databases

```sh
docker-compose run --rm web rake db:setup
```

### Create an admin user

```sh
docker-compose run --rm web rake spets:add_sysadmin_user
```

### Load the postcode, constituency and region data

```sh
docker-compose run --rm web rake spets:geography:import
```

### Fetch the member list

```sh
docker-compose run --rm web rails runner 'FetchMembersJob.perform_now'
```

### Enable signature counting

```sh
docker-compose run --rm web rails runner 'Site.enable_signature_counts!(interval: 10)'
```

### Start the services

```sh
docker-compose up
```

Once the services have started you can access the [front end][2], [back end][3] and any [emails sent][4].

## Tests

You can run the full test suite using following command:

```sh
docker-compose run --rm web rake
```

Individual specs can be run using the following command:

```sh
docker-compose run --rm web rspec spec/models/site_spec.rb
```

Similarly, individual cucumber features can be run using the following command:

```sh
docker-compose run --rm web cucumber features/suzie_views_a_petition.feature
```

Specs can be automatically run on file changes with `guard`:

```sh
docker-compose run --rm web bundle exec guard
```

[1]: https://www.docker.com/products/docker-desktop
[2]: http://localhost:3000/
[3]: http://localhost:3000/admin
[4]: http://localhost:1080/
