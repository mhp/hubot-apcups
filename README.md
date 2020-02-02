# hubot-apcups

Monitor UPSs managed by apcupsd

## Installation

In hubot project repo, run:

`npm install hubot-apcups --save`

Then add **hubot-apcups** to your `external-scripts.json`:

```json
[
  "hubot-apcups"
]
```

## APCUPSD configuration

For UPS events to be routed to hubot, copy the script and links from
`apcupsd.scripts` into `/etc/apcupsd`, amending as necessary.

For hubot to interrogate APCUPSD, make sure that `NISIP` in
`/etc/apcupsd/apcupsd.conf` is set appropriately, and then configure
hubot with a command like `hubot ups configure myups apc-ip 3551`.

## Sample Interaction

```
user1>> hubot ups status
hubot>> network: ONLINE line=242.0 Volts load=5.0 Percent
hubot>> servers: ONLINE line=240.0 Volts load=8.0 Percent

```
