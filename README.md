# Scottish Petitions

This is the code base for the Scottish Parliament's petitions service (https://petitions.parliament.scot).

## Setup

We recommend using [Docker Desktop][1] to get setup quickly. If you'd prefer not to use Docker then you'll need Ruby (3.2+), Node (20+) and PostgreSQL (12+) installed.

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

### Create the database

```
docker compose run --rm web rake db:prepare
```

### Create an admin user

```
docker compose run --rm web rake spets:add_sysadmin_user
```

### Load the postcode, constituency and region data

```
docker compose run --rm web rake spets:geography:import
```

### Fetch the member list

```
docker compose run --rm web rails runner 'FetchMembersJob.perform_now'
```

### Enable signature counting

```
docker-compose run --rm web rails runner 'Site.enable_signature_counts!(interval: 10)'
```

### Start the services

```
docker compose up
```

Once the services have started you can access the [front end][2] and [back end][3].

## Tests

Before running any tests the database needs to be prepared:

```
docker compose run --rm web rake db:test:prepare
```

You can run the full test suite using following command:

```
docker compose run --rm web rake
```

Individual specs can be run using the following command:

```
docker compose run --rm web rspec spec/models/site_spec.rb
```

Similarly, individual cucumber features can be run using the following command:

```
docker compose run --rm web cucumber features/suzie_views_a_petition.feature
```

[1]: https://www.docker.com/products/docker-desktop
[2]: http://localhost:3000/
[3]: http://localhost:3000/admin
