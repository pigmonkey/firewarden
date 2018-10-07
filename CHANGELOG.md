# Change Log


## [ 1.0.3 ] - 2018-10-06

### Changed
- Always make files writable by user within the jail.
- Support private cache directory.


## [ 1.0.2 ] - 2018-08-30

### Changed
- Avoid using directories when building nonexistent files to create private `/opt` and `/srv`


## [ 1.0.1 ] - 2017-09-15

### Changed
- Prefer `$XDG_RUNTIME_DIR` for the jail's home, falling back to `/tmp/$USER` if not available.


## [ 1.0.0 ] - 2017-06-02

- Initial release
